#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
echo ''
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
sleep 1 && curl -s https://api.nodes.guru/logo.sh | bash && sleep 1

NODE=Zetachain
NODE_HOME=$HOME/.zetacored
BINARY=zetacored

if [ ! $VALIDATOR ]; then
    read -p "Enter validator name: " VALIDATOR
    echo 'export VALIDATOR='\"${VALIDATOR}\" >> $HOME/.bash_profile
fi
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
source $HOME/.bash_profile
sleep 1
cd $HOME
sudo apt update
sudo apt install sudo curl wget make clang pkg-config tmux systemd libssl-dev lsb-release build-essential vim git jq ncdu bsdmainutils lz4 zip htop -y < "/dev/null"
echo -e '\n\e[42mInstall Go\e[0m\n' && sleep 1
cd $HOME
if [ ! -f "/usr/local/go/bin/go" ]; then
    VERSION=1.20.6
    wget -O go.tar.gz https://go.dev/dl/go$VERSION.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go.tar.gz && rm go.tar.gz
    echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
    echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
    echo 'export GO111MODULE=on' >> $HOME/.bash_profile
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
    go version
fi

if lsb_release -r | grep -q 20 ; then
    wget -O $HOME/zetacored https://github.com/zeta-chain/node/releases/download/v6.0.0/zetacored-ubuntu-20-amd64
elif lsb_release -r | grep -q 22 ; then
    wget -O $HOME/zetacored https://github.com/zeta-chain/node/releases/download/v6.0.0/zetacored-ubuntu-22-amd64
else 
    echo -e "\e[31mInstallation is not possible, unsupported OS.\e[39m"
    exit
fi
sudo chmod +x $HOME/zetacored
sudo mv $HOME/zetacored /usr/local/bin/zetacored

echo -e '\n\e[42mDownloading ZetaChain Configuration Files\e[0m\n' && sleep 1

mkdir -p $HOME/.zetacored/config/
wget -O $HOME/.zetacored/config/app.toml     https://raw.githubusercontent.com/zeta-chain/network-athens3/main/network_files/config/app.toml
wget -O $HOME/.zetacored/config/client.toml  https://raw.githubusercontent.com/zeta-chain/network-athens3/main/network_files/config/client.toml
wget -O $HOME/.zetacored/config/config.toml  https://raw.githubusercontent.com/zeta-chain/network-athens3/main/network_files/config/config.toml
wget -O $HOME/.zetacored/config/genesis.json https://raw.githubusercontent.com/zeta-chain/network-athens3/main/network_files/config/genesis.json

SNAP_RPC="http://52.3.196.71:26657"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.zetacored/config/config.toml

echo -e '\n\e[42mRunning\e[0m\n' && sleep 1
echo -e '\n\e[42mCreating a service\e[0m\n' && sleep 1

echo "[Unit]
Description=$NODE Node
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=/usr/local/bin/$BINARY start --home $HOME/.zetacored/ --log_format json  --log_level info --moniker $VALIDATOR
Restart=on-failure
LimitNOFILE=262144

[Install]
WantedBy=multi-user.target" > $HOME/$BINARY.service
sudo mv $HOME/$BINARY.service /etc/systemd/system
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
echo -e '\n\e[42mRunning a service\e[0m\n' && sleep 1
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable $BINARY
sudo systemctl restart $BINARY

echo -e '\n\e[42mCheck node status\e[0m\n' && sleep 1
if [[ `service $BINARY status | grep active` =~ "running" ]]; then
  echo -e "Your $NODE node \e[32minstalled and works\e[39m!"
  echo -e "You can check node status by the command \e[7mservice $BINARY status\e[0m"
  echo -e "Press \e[7mQ\e[0m for exit from status menu"
else
  echo -e "Your $NODE node \e[31mwas not installed correctly\e[39m, please reinstall."
fi
