data "vsphere_datastore" "datastore1" {
  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "pool" {
  name          = "StockholmSmall/Resources"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "vm_network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "admin_network" {
  name          = vsphere_host_port_group.pg_admin.name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "user_network" {
  name          = vsphere_host_port_group.pg_user.name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "template" {
  name          = "debian-10-template"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_datacenter" "datacenter" {
  name = "Stockholm"
}

data "vsphere_host" "esxi_host" {
  name          = "192.168.86.150"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}