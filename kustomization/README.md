### kustomization

- [Glossary](https://kubectl.docs.kubernetes.io/references/kustomize/glossary/)
- [Kustomization Files](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/)


There is npot any hard rules for kustomization folder structure - but better to decorate which is more understandable . From the officila site kustomization follws like :

```
├── base
│   ├── deployment.yaml
│   ├── kustomization.yaml
│   └── service.yaml
└── overlays
    ├── dev
    │   ├── kustomization.yaml
    │   └── patch.yaml
    ├── prod
    │   ├── kustomization.yaml
    │   └── patch.yaml
    └── staging
        ├── kustomization.yaml
        └── patch.yaml
```

and the command to use to evaluate this is :

```
 kustomize build someapp/overlays/staging |\
     kubectl apply -f -

 kustomize build someapp/overlays/production |\
     kubectl apply -f -
```
