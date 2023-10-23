#!/bin/bash
# <UDF name="HOSTNAME" Label="Compute Hostname" example="Hostname of the Compute instance."/>
# <UDF name="EDGEGRID_ACCOUNT_KEY" Label="Akamai EdgeGrid Account Key" example="Account Key to be used all APIs/CLI or Terraform calls." default=""/>
# <UDF name="EDGEGRID_HOST" Label="Akamai EdgeGrid Hostname" example="Hostname used to authenticate in Akamai Intelligent Platform using APIs/CLI or Terraform calls."/>
# <UDF name="EDGEGRID_ACCESS_TOKEN" Label="Akamai EdgeGrid Access Token" example="Access Token used to authenticate in Akamai Intelligent Platform using APIs/CLI or Terraform calls."/>
# <UDF name="EDGEGRID_CLIENT_TOKEN" Label="Akamai EdgeGrid Client Token" example="Client Token used to authenticate in Akamai Intelligent Platform using APIs/CLI or Terraform calls."/>
# <UDF name="EDGEGRID_CLIENT_SECRET" Label="Akamai EdgeGrid Client Secret" example="Client Secret used to authenticate in Akamai Intelligent Platform using APIs/CLI or Terraform calls."/>
# <UDF name="ACC_TOKEN" Label="Akamai Connected Cloud Access Key" example="Token used to authenticate in the Akamai Connected Cloud using APIs/CLI or Terraform calls."/>
# <UDF name="REMOTEBACKEND_ID" Label="Terraform Remote Backend Identifier" example="Identifier of Terraform Remote Backend used to control the provisioning states of the resources."/>
# <UDF name="REMOTEBACKEND_REGION" Label="Terraform Remote Backend Region" example="Region of Terraform Remote Backend used to control the provisioning states of the resources."/>

function createEnvironmentFile() {
  echo "export HOSTNAME=$HOSTNAME" > /root/.env
  echo "export EDGEGRID_ACCOUNT_KEY=$EDGEGRID_ACCOUNT_KEY" >> /root/.env
  echo "export EDGEGRID_HOST=$EDGEGRID_HOST" >> /root/.env
  echo "export EDGEGRID_ACCESS_TOKEN=$EDGEGRID_ACCESS_TOKEN" >> /root/.env
  echo "export EDGEGRID_CLIENT_TOKEN=$EDGEGRID_CLIENT_TOKEN" >> /root/.env
  echo "export EDGEGRID_CLIENT_SECRET=$EDGEGRID_CLIENT_SECRET" >> /root/.env
  echo "export ACC_TOKEN=$ACC_TOKEN" >> /root/.env
  echo "export REMOTEBACKEND_ID=$REMOTEBACKEND_ID" >> /root/.env
  echo "export REMOTEBACKEND_REGION=$REMOTEBACKEND_REGION" >> /root/.env
}

function setHostname() {
  echo "Setting the hostname..." > /dev/ttyS0

  hostnamectl set-hostname "$HOSTNAME"
}

function updateSystem() {
  echo "Updating the system..." > /dev/ttyS0

  createEnvironmentFile
  setHostname

  apt update
  apt -y upgrade
}

function installRequiredSoftware() {
  echo "Installing required software..." > /dev/ttyS0

  apt -y install ca-certificates \
                 gnupg2 \
                 curl \
                 wget \
                 vim \
                 git

  installTerraform
  installDocker
  installCiCd
}

function installTerraform() {
  echo "Installing Terraform..." > /dev/ttyS0

  wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
  apt update
  apt -y install terraform
}

function installDocker() {
  echo "Installing Docker..." > /dev/ttyS0

  curl https://get.docker.com | sh -

  systemctl enable docker
}

function installCiCd() {
  echo "Installing CI/CD..." > /dev/ttyS0

  git clone https://github.com/fvilarinho/cicdzerotohero /root/cicdzerotohero

  cd /root/cicdzerotohero || exit 1

  rm -rf .git
  rm -f .gitignore
}

function setupCiCd() {
  echo "Setting up the CI/CD..." > /dev/ttyS0

  cd /root/cicdzerotohero || exit 1

  ./setup.sh
}

function startCiCd() {
  echo "Starting CI/CD..." > /dev/ttyS0

  cd /root/cicdzerotohero || exit 1

  ./start.sh

  c=0

  while true; do
    containerId=$(docker ps | grep jenkins | awk '{print $1}')

    if [ -n "$containerId" ]; then
      while true; do
        docker cp "$containerId":/var/jenkins_home/secrets/initialAdminPassword /root/cicdzerotohero/initialAdminPassword

        if [ -f /root/cicdzerotohero/initialAdminPassword ]; then
          echo > /dev/ttyS0
          echo "Jenkins initial password is: " > /dev/ttyS0

          cat /root/cicdzerotohero/initialAdminPassword > /dev/ttyS0

          break
        else
          if [ $c -eq 0 ]; then
            echo "Waiting for CI/CD boot..." > /dev/ttyS0

            c=1
          fi

          sleep 1
        fi
      done

      break
    else
      if [ $c -eq 0 ]; then
        echo "Waiting for CI/CD boot..." > /dev/ttyS0

        c=1
      fi

      sleep 1
    fi
  done
}

function main() {
  updateSystem
  installRequiredSoftware
  setupCiCd
  #startCiCd

  echo > /dev/ttyS0
  echo "Continue the setup in the UI!" > /dev/ttyS0
  echo > /dev/ttyS0

  ip=$(curl ipinfo.io/ip)

  echo "For Gitea, access https://$ip:8443" > /dev/ttyS0
  echo "For Jenkins, access https://$ip:8444" > /dev/ttyS0
}

main