# ansible-audiopi

This project contains scripts and playbooks based on ansible. It is used to manage my Raspberry Pi devices at home acting as AirPlay devices using HiFiBerry audio shields.

Currently I use a couple of Rasperry Pi 3+ together with either HiFiBerry AMP2 or HiFiBerry DAC+ shields. On the software side I am using the default Raspbian installation. This is important to make sure that the playbooks can run correctly.


## Usage
To run the playbooks you need at least one HiFiBerry-enabled Raspberry Pi and a working [ansible](https://www.ansible.com) installation. I will not cover the installation of ansible here but I can say that a [brew](https://brew.sh)-based installation on macOS works fine.

Required ansible version: >= 2.3

## Howto

### Installation of a new Airplay device

1. Insert a new (Micro-)SD card to your card reader that should become the storage of your HiFiBerry-enabled Raspberry Pi. This card should have a size of at least 4 GB if you use the lite image of Raspbian or of 8 GB if you want to use the normal image.

  1. Before you start, you need to [download a Raspbian image](https://www.raspberrypi.org/downloads/raspbian/) to your computer and unzip it.
  2. You also must know the device of the SD card in your card reader, i.e. `/dev/disk12` on a Darwin system or `/dev/mmcblk0` on a Linux system.

2. Run the setup script to install the Raspbian image to your SD card, e.g.

 ```sh
./scripts/install.sh -i ~/Downloads/2018-04-18-raspbian-stretch-lite.img -d /dev/disk12
 ```

 Follow the instructions on the screen to complete the Raspbian installation.

3. Put the SD card into your Raspberry and connect it to your ethernet (using a cable). Power the Rasperry on. Find out the IP address of your litte computer.

4. You now need to create a local user account on the Raspberry. This account will be created without specifying a password and limiting authorization to SSH's public key method.

  1. If you do not have an SSH key pair yet, you should create one:

    ```sh
ssh-keygen -b 8192
    ```

  2. Put your public SSH key to the `authorized_keys` file that will be copied to the Raspberry.

    ```sh
cat ~/.ssh/id_rsa.pub >> playbooks/files/authorized_keys
    ```

  3. Create the local user account on the Raspberry. You need the IP of the Raspberry to connect as the default user `pi`. This command will ask for the password of this user. By default, this is `raspberry`.

    ```sh
ansible-playbook -u pi -k -i <IP>, playbooks/createuser.yml -v
    ```

   This local user account will not have a password set. It will be added to `/etc/sudoers` with the permissions do run everyting as root without needing a password. The postinstall playbook below expects this behaviour.

5. If your new user account has been successfully created, you can install and configure the software needed to provide an Airplay endpoint. This postinstall playbook will also remove the Raspberry's default user for security reasons. After running this playbook you can only log in to your Raspberry by using your SSH key pair(s) that are defined in the `authorized_keys` file.

 ```sh
ansible-playbook -i <IP>, playbooks/postinstall.yml -v
 ```

  If you manually set a password for the local user created earlier, you need to call this playbook with the `--ask-sudo-pass` option to make ansible aware of the password needed to use sudo.


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

