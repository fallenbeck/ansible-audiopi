# ansible-audiopi

This project contains scripts and playbooks based on ansible. It is used to manage my Raspberry Pi devices at home acting as AirPlay devices using HiFiBerry audio shields.

Currently I use a couple of Rasperry Pi 3+ together with either HiFiBerry AMP2 or HiFiBerry DAC+ shields. On the software side I am using the default Raspbian installation. This is important to make sure that the playbooks can run correctly.

This document is structured as follows:
1. Requirements - Brief description of the requirements to use this playbooks.
2. tl;dr - Short list how to set up your device and what playbooks to use.
3. Installation - More detailed installation instructions giving some information of the individual steps carried out.
4. Playbooks - Additional information on the playbooks of this project.
5. Troubleshooting - If you run into any problems this is the section you should look into. It will grow over time when your bug reports come in. ;-)



## Requirements
To run the playbooks you need at least one HiFiBerry-enabled Raspberry Pi and a working [ansible](https://www.ansible.com) installation. I will not cover the installation of ansible here but I can say that a [brew](https://brew.sh)-based installation on macOS works fine.

Required ansible version: >= 2.4



## tl;dr

1. Assemble the hardware.
2. Put the Raspberry Pi's MicroSD card into a card reader connected to your computer and figure out the device to access it.
3. Download the [Raspbian ISO file](https://www.raspberrypi.org/downloads/raspbian/).
4. Dump the ISO to the MicroSD card, i.e. by using `scripts/install.sh`.
5. If you did not use `install.sh` to create the MicroSD card, you need to manually install the SSH server on Raspbian.
6. Create the file `playbooks/files/authorized_keys` containing the public SSH keys of all accounts that should be able to log into your Airplay devices.
7. Put the MicroSD card into the Raspberry Pi, connect the Pi to your network, boot it up and find out its IP address
8. Create a local user on the device. This will copy over the `authorized_keys` file you created above. This will be done by using the default user `pi`. You need to provide the password of this user which is usually `raspberry`.
  ```sh
ansible-playbook -u pi -k -i <IP>, playbooks/createuser.yml
  ```

9. Run the postinstall playbook to configure Raspbian correctly for your device and environment. This will also remove the default system user `pi`.
  ```sh
ansible-playbook -i <IP>, playbooks/postinstall-os.yml
  ```

10. Install the `shairport-sync` software stack to Airplayify your device. If you want to fine-tune your device, have a look at the config file `playbooks/templates/shairport-sync.conf.j2`.
  ```sh
ansible-playbook -i hosts playbooks/shairport-sync.yml
  ```



## Installation

If you want to better understand what actions are carried out by the playbooks, this section will provide you with further information. I also recommend having a look at the playbook files in the `playbooks/` folder.

### Install Raspbian

Insert a new (Micro-)SD card to your card reader that should become the storage of your HiFiBerry-enabled Raspberry Pi. This card should have a size of at least 4 GB if you use the lite image of Raspbian or of 8 GB if you want to use the normal image.

Before you start, you need to [download a Raspbian image](https://www.raspberrypi.org/downloads/raspbian/) to your computer and unzip it.

You also must know the device of the SD card in your card reader, i.e. `/dev/disk12` on a Darwin system or `/dev/mmcblk0` on a Linux system.

Run the setup script to install the Raspbian image to your SD card, e.g.

```sh
./scripts/install.sh -i ~/Downloads/2018-04-18-raspbian-stretch-lite.img -d /dev/disk12
```

Follow the instructions on the screen to complete the Raspbian installation.


### Power on the Rasbperry Pi and connect it to the network

Put the SD card into your Raspberry and connect it to your ethernet (using a cable). Power the Rasperry on. Find out the IP address of your litte computer.


### SSH keys

You now need to create a local user account on the Raspberry. This account will be created without specifying a password and limiting authorization to SSH's public key method.

At this point you have 2 possibilities. Either you create a new SSH key pair or you can use an already exising key pair.

#### Create new SSH key pair

If you do not have an SSH key pair yet (or if you want to use a dedicated key pair for logging in to your Airplay devices) you must create one:

```sh
ssh-keygen -t ed25519 -P "" -f playbooks/files/id_ed25519
cat playbooks/files/id_ed25519 >> playbooks/files/authorized_keys
```

This command will create an SSH key pair without a passphrase and put it in the playbooks/files directory and add the public key to the authorized_keys file.

#### Use existing key pair

If you already have a key pair that you want to use you need to put your existing public SSH key to the `authorized_keys` file that will be copied to the Raspberry. If you want to grant access to different users you can simply append additional public keys to this file.

```sh
cat ~/.ssh/id_ed25519.pub >> playbooks/files/authorized_keys
```

### Create local user

Create the local user account on the Raspberry. You need the IP of the Raspberry to connect as the default user `pi`. This command will ask for the password of this user. By default, this is `raspberry`.

```sh
ansible-playbook -u pi -k -i <IP>, playbooks/createuser.yml
```

This local user account will not have a password set. It will be added to `/etc/sudoers` with the permissions do run everyting as root without needing a password. The postinstall playbook below expects this behaviour.


### Configure the Raspberry for your environment

If your new user account has been successfully created, you can install and configure the software needed to provide an Airplay endpoint. This postinstall playbook will also remove the Raspberry's default user for security reasons. After running this playbook you can only log in to your Raspberry by using your SSH key pair(s) that are defined in the `authorized_keys` file.

```sh
ansible-playbook -i <IP>, playbooks/postinstall-os.yml
```

If you manually set a password for the local user created earlier, you need to call this playbook with the `--ask-sudo-pass` option to make ansible aware of the password needed to use sudo.


### shairport-sync

To install the `shairport-sync` software (and the Airplay software stack) you can run the `shairport-sync.yml` playbook. We use the `hosts` inventory file that contains the hostnames of all airplay devices. These hostnames need to be resolvable and reachable over network to connect to these devices to run the playbook's tasks.

You can configure this playbook to some extend using the `group_vars/speakers` file.

```sh
ansible-playbook -i hosts playbooks/shairport-sync.yml
```



## Playbooks
I will create my playbooks in the `playbooks` folder of this project. To run a playbook, use one of the default ansible commands:

To update all existing devices, simply run.
```sh
ansible-playbook --inventory hosts playbooks/update.yml
```

This will install a new Linux kernel on the devices and perform an update on all software packages managed by aptitute. It will reboot your devices after the update has been finished.

Please have a look at the playbooks to get an idea what actions will be run on the devices. I hope that my naming will make clear what will happen on the software side. :)


### Advanced usage

If you want to run a playbook on a single device, you can provide a list instead of a file when specifying an `--inventory`:

```sh
ansible-playbook --inventory "esszimmer," playbooks/update.yml
```


## Troubleshooting

### ERROR! no action detected in task. This often indicates a misspelled module name, or incorrect module path.

If you try to execute a playbook using ansible version <= 2.4 you will run into the following error:

```
$ ansible-playbook -i hosts -v playbooks/fetch-settings.yml
Using /etc/ansible/ansible.cfg as config file
ERROR! no action detected in task. This often indicates a misspelled module name, or incorrect module path.

The error appears to have been in '/home/fallenbeck/src/ansible-audiopi/playbooks/fetch-settings.yml': line 12, column 7, but may
be elsewhere in the file depending on the exact syntax problem.

The offending line appears to be:

  tasks:
    - name: Fetch authorized_keys
      ^ here


The error appears to have been in '/home/fallenbeck/src/ansible-audiopi/playbooks/fetch-settings.yml': line 12, column 7, but may
be elsewhere in the file depending on the exact syntax problem.

The offending line appears to be:

  tasks:
    - name: Fetch authorized_keys
      ^ here
```

This is because the `include_tasks` module used in these playbooks were introduced by ansible 2.4. You cannot execute these playbooks with older ansible versions.


### unable to calculate the checksum of the remote file

If you run into the following error, e.g. when running the `fetch-settings` playbook, your host name resolution might not work:

```
TASK [Get authorized_keys file from .ssh] *******************************************************************************************************************************************
fatal: [esszimmer]: FAILED! => {"changed": false, "file": ".ssh/authorized_keys", "msg": "unable to calculate the checksum of the remote file"}
  to retry, use: --limit @/Users/fallenbeck/src/ansible-audiopi/playbooks/fetch-settings.retry
```

In my case I tried to connect to `esszimmer` but this hostname could not be resolved. You should check your DNS settings or add the hostname(s) and the corresponding IP(s) to `/etc/hosts`.
