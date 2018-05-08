# ansible-audiopi

This project contains scripts and playbooks based on ansible. It is used to manage my Raspberry Pi devices at home acting as AirPlay devices using HiFiBerry audio shields.

Currently I use a couple of Rasperry Pi 3+ together with either HiFiBerry AMP2 or HiFiBerry DAC+ shields. On the software side I am using the default Raspbian installation. This is important to make sure that the playbooks can run correctly.


## Usage
To run the playbooks you need at least one HiFiBerry-enabled Raspberry Pi and a working [ansible](https://www.ansible.com) installation. I will not cover the installation of ansible here but I can say that a [brew](https://brew.sh)-based installation on macOS works fine.

Required ansible version: >= 2.3

### Playbooks
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

