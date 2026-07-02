<!--
  Header for the complete example README. Edit this file, then run `just docs`
  (or ./Sort-LdoTerraform.ps1 -IncludeExamples) to regenerate the section between the markers.
  The example's main.tf is embedded into the README automatically (see .terraform-docs.yml).
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="200">
    </picture>
  </a>
</div>

# Complete example

The full surface of the module: a generated key with the secure defaults (RSA 4096, private key
written to the vault through value_wo), a generated key exercising every storage option (size, secret
name, OpenSSH format, content type, expiry, a bumped rotation version, per-key tags), a generated
ED25519 key, and a bring-your-own public key alongside them. The vault the private keys land in allow-lists the runner's
egress IP (this subscription enforces default-deny network rules on key vaults) and uses access
policies so the data-plane writes work immediately. Run it with `just e2e complete`, which applies
the stack then always destroys it.

[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
