# Setting Up ORAN

This document provides a step-by-step guide to setting up an Open Radio Access Network (ORAN) environment. Follow the instructions below to configure your ORAN setup.

## Details

### E2AP Terminology

- **RAN Function**: A function in an E2 Node (UE context handling, paging, Handover, cell configuration)
  - **RAN Function ID**: Identifier of the RAN Function
- **RIC Service**: A service provided by an E2 Node
  - E2 Node provides access to messages, measurements, and/or enables control from the near-RT RIC
  - **RIC Action ID**: Identifier of the RIC Action
- **Information Elements (IEs)**: Data item containing a label field, length, and value
- **Message**: Group of ordered and nested IEs (E2 Setup request, setup response, subscription request)
- **Procedure**: Sequential exchange of a set of messages (Setup procedure, subscription procedure)

### E2 Setup Procedure

- E2 is preconfigured with Near-RT RIC address and service information, and E2 node configuration
- SCTP connection from E2 Node to Near-RT RIC is established
- E2 Setup Request message is sent from E2 Node to Near-RT RIC
- Near-RT RIC extracts lists of supported RIC Services and mapping of services to functions and stores information.
- Near-RT RIC extracts list of E2 Node configuration information and stores it.
- E2 Setup Response (RIC Service and E2 Node configuration Ack)

### RIC Services - Types

- **Report Service**:
  - The Report Service is triggered to send RIC Indication messages (of  type report) that can contain data and telemetry from an E2 Node, upon subscription from an xApp.
  - The report messages can be configured to be sent periodically during subscription

- **Insert Service**:
  - Through the Insert service an xApp can suspend a specific procedure upon event trigger (through  subscription) and get details about suspended procedures through RIC Indication messages (of  type insert).
  - The procedure can be halted till a timer expires/till a RIC control message is received.

- **Control Service**:
  - The E2 node can receive RIC Control messages triggered autonomously by the RIC (xApp) or due  to the consequence of  reception of  an Insert message.

- **Policy Service**:
  - The policy service allows an xApp to request the E2 node to execute a specific policy (through a Subscription Message) after the occurrence of  a specific event.
  - No halting of  any procedure. The E2 node adopts the policy specified.

- **Query Service**:
  - The E2 Node allows the RIC (xApp) to query RAN/UE-specific information.

### E2 Service Models (E2SM)

- Each RAN Function is associated with one or more E2 Service Models.
- The RIC services provided by the RAN function, the message types used, and their styles are specified in the E2 Service Model.
- The Service Model also contains description of  RAN function dependent
- Information Elements used in the E2 messages.
- xApps need to have the same service Model definitions to effectively communicate with the RAN functions.

### E2SM-KPM

- The Key Performance Metrics (KPM) Monitor RAN function exposes available measurements from O-DU, O-CU-CP, O-CU-UP and periodically reports measurements subscribed from near-RT RIC (xApp).
- The KPM Monitor RAN function provides the Report service in the following styles
  - E2 Node Measurement.
  - E2 Node Measurement for a single UE.
  - Condition-based, UE-level E2 Node Measurement.
  - Common Condition-based, UE-level E2 Node Measurement.
  - E2 Node Measurements for multiple UEs.

## Installation

### Installing Open Air Interface

#### Dependencies

```bash
sudo apt update
sudo apt install git net-tools unzip ccache libcap-dev libatlas-base-dev libblas3 liblapack3 gfortran
cd /workspaces/5GORAN/MiniProject
git submodule add https://github.com/gregoryw3/openairinterface5g.git openairinterface5g
cd /workspaces/5GORAN/MiniProject/openairinterface5g/cmake_targets
./build_oai -I
```

Make sure you are using GCC 12 or 13:

```bash
gcc --version
```

### Installing OAI CN 5G

- Install Docker

Configuration Files:

```bash
wget -O /workspaces/5GORAN/MiniProject/oai-cn5g.zip https://gitlab.eurecom.fr/oai/openairinterface5g/-/archive/develop/openairinterface5g-develop.zip?path=doc/tutorial_resources/oai-cn5g

unzip /workspaces/5GORAN/MiniProject/oai-cn5g.zip

mv /workspaces/5GORAN/MiniProject/openairinterface5g-develop-doc-tutorial_resources-oai-cn5g/doc/tutorial_resources/oai-cn5g ~/MiniProject/oai-cn5g

rm -r /workspaces/5GORAN/MiniProject/openairinterface5g-develop-doc-tutorial_resources-oai-cn5g ~/MiniProject/oai-cn5g.zip

cd /workspaces/5GORAN/MiniProject/oai-cn5g
sudo docker compose pull
```

#### Starting OAI CN 5G

```bash
cd /workspaces/5GORAN/MiniProject/oai-cn5g
docker compose up -d
```

#### Stopping OAI CN 5G

```bash
cd /workspaces/5GORAN/MiniProject/oai-cn5g
docker compose down
```

### Installing OAI RAN

```bash
cd /workspaces/5GORAN/MiniProject/openairinterface5g/cmake_targets
./build_oai -w SIMU --gNB --nrUE --build-e2 --ninja
```

### Installing Swig for FlexRIC

```bash
sudo apt install libsctp-dev cmake-curses-gui libpcre2-dev
cd /workspaces/5GORAN/MiniProject
git submodule add https://github.com/gregoryw3/swig.git
cd swig
git checkout release-4.1
./autogen.sh
./configure --prefix=/usr/
make -j`nproc`
sudo make install
cd /workspaces/5GORAN/MiniProject
```

### Installing FlexRIC

```bash
cd /workspaces/5GORAN/MiniProject
git submodule add https://github.com/gregoryw3/flexric.git flexric
cd flexric
git checkout df754a85
```

```bash
cd flexric
mkdir build
cd build
cmake ../
make -j`nproc`
sudo make install
cd /workspaces/5GORAN/MiniProject
```

## Running Core Network - Terminal 1

```bash
cd /workspaces/5GORAN/MiniProject/oai-cn5g
docker compose up -d
```

## Running FlexRIC - Terminal 2

```bash
cd /workspaces/5GORAN/MiniProject
./flexric/build/examples/ric/nearRT-RIC
```

## Start the gNB - Terminal 3

First we need to edit the configuration file to point to the FlexRIC instance.

```bash
cd /workspaces/5GORAN/MiniProject/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/
nano gnb.sa.band78.fr1.106PRB.usrpb210.conf
```

Now we can start the gNB:

```bash
cd /workspaces/5GORAN/MiniProject/openairinterface5g/cmake_targets/ran_build/build
sudo ./nr-softmodem -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band78.fr1.106PRB.usrpb210.conf --gNBs.[0].min_rxtxtime 6 --rfsim
```

## Start the UE - Terminal 4

```bash
cd /workspaces/5GORAN/MiniProject/openairinterface5g/cmake_targets/ran_build/build
sudo ./nr-uesoftmodem -r 106 --numerology 1 --band 78 -C 3619200000 --uicc0.imsi 001010000000001 --rfsim
```

## Start Traffic - Terminal 5

```bash
ping 192.168.70.135 -I oaitun_ue1
```

## Start the KPM xApp - Terminal 6

```bash
cd /workspaces/5GORAN/MiniProject/flexric/
./build/examples/xApp/c/monitor/xapp_kpm_moni
```
