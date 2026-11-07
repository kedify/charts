#!/usr/bin/env python3
"""Check real export rotation and RBAC without printing credentials."""
import argparse
import base64
import json
import subprocess
import time

import yaml


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--namespace", default="keda")
    parser.add_argument("--secret", default="vcluster-tenant-a")
    parser.add_argument("--vcluster-namespace", default="vcluster-tenant-a")
    parser.add_argument("--vcluster-service-account", default="vc-tenant-a")
    parser.add_argument("--tenant-service-account", default="system:serviceaccount:default:kedify-runtime")
    parser.add_argument("--agent-deployment", default="kedify-agent")
    parser.add_argument("--keda-deployment", default="keda-operator")
    parser.add_argument("--kpa-deployment", default="kpa")
    args = parser.parse_args()

    def kubectl(*command):
        result = subprocess.run(["kubectl", "--request-timeout=10s", *command], capture_output=True, text=True)
        if result.returncode:
            raise RuntimeError("kubectl failed: " + result.stderr.strip())
        return result.stdout.strip()

    def allowed(identity, verb, resource, namespace=None, all_namespaces=False):
        command = ["kubectl", "--request-timeout=10s", "--as=" + identity, "auth", "can-i", verb, resource]
        command += ["--all-namespaces"] if all_namespaces else ["-n", namespace or args.namespace]
        result = subprocess.run(command, capture_output=True, text=True)
        if result.stdout.strip() not in ("yes", "no"):
            raise RuntimeError("authorization check failed: " + result.stderr.strip())
        return result.stdout.strip() == "yes"

    for name in [args.agent_deployment, args.keda_deployment, args.kpa_deployment]:
        deployment = json.loads(kubectl("-n", args.namespace, "get", "deployment", name, "-o", "json"))
        sa = deployment["spec"]["template"]["spec"].get("serviceAccountName", "default")
        identity = f"system:serviceaccount:{args.namespace}:{sa}"
        assert not allowed(identity, "list", "secrets", all_namespaces=True), f"{sa} can list host Secrets"
        assert not allowed(identity, "watch", "secrets", all_namespaces=True), f"{sa} can watch host Secrets"
        assert not allowed(identity, "get", "secret/unrelated", namespace=args.vcluster_namespace), f"{sa} can read tenant host Secrets"
        assert allowed(identity, "get", "secret/" + args.secret), f"{sa} cannot read registration Secret"
    writer = f"system:serviceaccount:{args.vcluster_namespace}:{args.vcluster_service_account}"
    assert allowed(writer, "get", "secret/" + args.secret)
    assert allowed(writer, "patch", "secret/" + args.secret)
    # Named list/watch are authorized when the client supplies metadata.name.
    kubectl("--as=" + writer, "-n", args.namespace, "get", "secrets",
            "--field-selector=metadata.name=" + args.secret, "-o", "name")
    assert not allowed(writer, "list", "secrets")
    assert not allowed(writer, "watch", "secrets")
    assert not allowed(writer, "get", "secret/unrelated")
    assert not allowed(writer, "create", "secrets")

    def snapshot():
        secret = json.loads(kubectl("-n", args.namespace, "get", "secret", args.secret, "-o", "json"))
        assert secret["metadata"]["labels"]["sigs.k8s.io/multicluster-runtime-kubeconfig"] == "vcluster"
        config = yaml.safe_load(base64.b64decode(secret["data"]["config"]))
        selected = next(c["context"] for c in config["contexts"] if c["name"] == config["current-context"])
        auth = next(u["user"] for u in config["users"] if u["name"] == selected["user"])
        assert set(auth) == {"token"}, "export contains additional credentials"
        cluster = next(c["cluster"] for c in config["clusters"] if c["name"] == selected["cluster"])
        assert cluster.get("certificate-authority-data") and not cluster.get("insecure-skip-tls-verify")
        token = auth["token"]
        payload = token.split(".")[1]
        claims = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
        # Claim inspection is diagnostic; API authentication verifies signatures.
        assert claims["sub"] == args.tenant_service_account
        assert 0 < claims["exp"] - claims["iat"] <= 600, "issuer exceeded requested ten-minute lifetime"
        registrations = json.loads(kubectl("-n", args.namespace, "get", "clusterregistrations", "-o", "json"))["items"]
        matches = [r for r in registrations if r["spec"]["kubeconfigSecretRef"] == {"name": args.secret, "key": "config"}]
        assert len(matches) == 1, "expected exactly one direct registration"
        registration = matches[0]
        assert any(c["type"] == "Ready" and c["status"] == "True" for c in registration.get("status", {}).get("conditions", [])), "registration is not Ready"
        return secret["metadata"]["uid"], registration["metadata"]["uid"], token, claims

    first = snapshot()
    deadline = first[3]["exp"] - 15
    print("RBAC, direct registration and ten-minute ServiceAccount export verified. Waiting for rotation.", flush=True)
    while time.time() < deadline:
        current = snapshot()
        if current[2] != first[2]:
            assert current[:2] == first[:2], "rotation recreated the Secret or registration"
            assert current[3]["exp"] > first[3]["exp"], "rotation did not extend validity"
            print("Token rotated before expiry; Secret and registration identities stayed stable.")
            return
        time.sleep(5)
    raise RuntimeError("token was not renewed before expiry")


if __name__ == "__main__":
    main()
