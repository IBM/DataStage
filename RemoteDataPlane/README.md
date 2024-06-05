# DataStage PXRuntime on Remote Data Plane

To support deploying DataStage PXRuntime on a remote data plane, the DataStage operator needs to be deployed to the management namespace of the physical location associated with the remote data plane.

## Requirements

- Deploy the physical location and associate it with a [remote data plane](https://www.ibm.com/docs/en/cloud-paks/cp-data/5.0.x?topic=instances-deploying-remote-data-plane)

- Configure the [global pull secret](https://www.ibm.com/docs/en/cloud-paks/cp-data/5.0.x?topic=cluster-updating-global-image-pull-secret)

Note: If using a private registry, an [image content source policy](https://www.ibm.com/docs/en/cloud-paks/cp-data/5.0.x?topic=registry-configuring-image-content-source-policy) will need to be configured. [Image mirroring](https://www.ibm.com/docs/en/cloud-paks/cp-data/5.0.x?topic=registry-mirroring-images-directly-private-container) will also be needed if the DataStage images has not been mirrored to this private registry.

## Deploying the DataStage operator

To deploy the operator on your physical location, login to the cluster via `oc` with cluster-admin role and run the command below. The latest operator will be deploy when version is omitted.

```
./deploy_operator.sh --namespace <management-namespace> [--version <version>]
```

# Using PXRuntime on a Remote Data Plane
To use a PXRuntime instance on a remote data plane with a project, a runtime environment must be created for that instance and that runtime environment must be selected as the project default. All resources needed at runtime will be created on the PXRuntime instance. As a result, the jobs in this project may not run on other PXRuntime instances.

Create a PXRuntime instance on the remote data plane:
1. On the `Instance details` page of the `New service instance` wizard for DataStace PX Runtime, select `Data Plane` instead of `Namespace`
2. Select the data plane with the physical location where the DataStage operator has been deployed

Note: Since this is not the default instance, only users that has been granted access to this instance will be able to run DataStage jobs on it.

Creating runtime environment:
1. From the project's `Manage` tab, select `Environments`
2. On the Environments page, select the `Templates` tab and click on `New template`
3. On the `New environment` dialog, select `DataStage` as the type and select the PXRuntime instance from the remote data plane for the hardware configuration.

Setting project default:
1. From the project's `Manage` tab, select `DataStage`
2. Select the runtime environment created previously as the default