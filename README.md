# brokelabs-charts

Helm chart of BrokeLabs: the operator, the api (which also serves the web UI), the gateway and PostgreSQL, plus the CRDs, the RBAC of each component and the cluster-wide `PlatformConfig`.

> Status: M4. Single-machine profile with a PostgreSQL pod; the cluster profile adds replicas and leader election.

Components are versioned on their own: `versions` in `values.yaml` pins the released tag of each component image (`ghcr.io/sigeth/brokelabs-<component>:<version>`, published by the component's `release` workflow when it is tagged). Bump a component there when it is released.

## Requirements

- Kubernetes 1.36 or later: the chart's admission policies (user namespaces for `userns` and `vcluster` machines, the guard on synced NetworkPolicies) use `MutatingAdmissionPolicy`.
- Cilium as the cluster network: it enforces NetworkPolicies and drops packets with a forged source address, which students who are root in their machines could otherwise send. `brokelabs addon cilium install` installs it (on k3s, start the server with `flannel-backend: none` and `disable-network-policy: true`).
- KubeVirt for `vm` machines: `brokelabs addon kubevirt install`.

## Install

```sh
helm install brokelabs ./brokelabs --namespace brokelabs-system --create-namespace
helm install brokelabs ./brokelabs --namespace brokelabs-system --create-namespace --set profile=cluster
```

| Value | Default | |
|---|---|---|
| `profile` | `single` | `single`: one Linux machine, `cluster`: 2 replicas + leader election |
| `image.registry` | `ghcr.io/sigeth` | Registry of the component images `brokelabs-<component>` |
| `versions.<component>` | released versions | Tag of each component image (operator, checker, api, web, gateway) |
| `image.tag` | empty | Overrides the tag of every component (e.g. `dev`) |
| `instancesNamespace.name` | `brokelabs-instances` | Namespace of student instances (Pod Security `restricted`) |
| `platform.*` | | Cluster-wide policy (`PlatformConfig`) |
| `api.signingKeySecret` | generated | Secret holding the Ed25519 access token key (`key.pem`) |
| `api.allowedOrigins` | `api.publicURL`, else `https://<httpRoute.hostname>` | Origins allowed to change state with the session cookie (CSRF) |
| `api.publicURL` | `https://<httpRoute.hostname>`, else `http://localhost:8080` | Platform URL as browsers reach it (single sign-on comes back to it) |
| `gateway.publicURL` | `https://<httpRoute.gatewayHostname>` | Gateway URL as browsers reach it (terminals) |
| `operator.checkerImage` | `<image.registry>/brokelabs-checker:<versions.checker>` | Built-in checker |
| `mode` | `solo` | `solo` (one person, no users or classrooms) or `organization` (accounts, roles and classrooms). |
| `admin.username` / `admin.passwordSecret` | `admin` / generated | First admin account (the only one in solo mode). The generated password is in the `brokelabs-admin` Secret. |
| `oidc.*` | disabled | Single sign-on with an OpenID Connect provider: `issuer`, `clientID`, `clientSecretName` (Secret key `clientSecret`), `label`, `scopes`, `groupsClaim`, `adminGroups` and `teacherGroups` (when set, the provider's groups decide roles at every sign-in), `caConfigMap` (key `ca.crt`). Register the redirect URI `<api.publicURL>/api/v1/auth/oidc/callback`. |
| `postgres.enabled` | `true` | Single PostgreSQL pod with a PVC. Set `false` and `api.databaseSecret` (key `url`) for an external database. |
| `httpRoute.*` | disabled | Gateway API routes for the UI/api and the gateway |

The api's access token key, the PostgreSQL password and the admin password are generated at install time and kept across upgrades. Read the admin password with:

```sh
kubectl -n brokelabs-system get secret brokelabs-admin -o jsonpath='{.data.password}' | base64 -d
```

## Permissions

| Component | Access |
|---|---|
| api | Read `Challenge`s, manage `ChallengeInstance`s and `CheckRun`s in the instances namespace, read ConfigMaps of the release namespace (inline package files) |
| gateway | Read `ChallengeInstance`s. `pods/exec` in instance namespaces only, through the `brokelabs-gateway-exec` ClusterRole the operator binds there. |
| checker | `pods/exec` in its instance namespace only (`brokelabs-checker-exec`, bound by the operator) |
| operator | Generated from its RBAC markers (`files/operator-role.yaml`). It binds only the gateway, checker and `brokelabs-vcluster` ClusterRoles. |
| vcluster | `brokelabs-vcluster` (`files/vcluster-role.yaml`), bound by the operator in the namespace of each virtual cluster |

## Files synced from other repositories

`brokelabs/crds/` comes from [brokelabs-core-go](https://github.com/Sigeth/brokelabs-core-go), at the tag in `CORE_GO_VERSION`. `brokelabs/files/operator-role.yaml` and `brokelabs/files/vcluster-role.yaml` come from [brokelabs-operator](https://github.com/Sigeth/brokelabs-operator), at the tag in `OPERATOR_VERSION`. Don't edit these files: bump the tag and run `make sync`. CI fails if they drift.

## Development

```sh
make lint template                                   # rendered/single.yaml, rendered/cluster.yaml
CORE_GO_DIR=../core-go OPERATOR_DIR=../operator make sync
```

## License

[MIT](LICENSE)
