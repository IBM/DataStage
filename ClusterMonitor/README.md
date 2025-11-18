# DataStage CPD cluster monitor script

This is a script to monitor CPD cluster for DataStage runtime pods. 
Download the script to a local temporary directory on a machine that has access to all px-runtime pods running in a CP4D cluster. 
Change the permission of the script to 755.

The script lists all nodes in the cluster with number of DataStage px-runtime pods and number of DataStage (osh/optimized pipeline) process running in each of the pods, number of jobs queued and running if the node contains px-runtime pods along with list of pods running in that node. The script fetches these details from the cluster once in every 10 seconds.

The script will also copy details of nodes and pods to all px-runtime pods whenever any of the nodes in cluster is cordoned or un-cordoned or removed.

Before cordoning a node that has px-runtime pod running in it, make sure that there is another px-runtime pod running by updating px-runtime pod replica count in CR. Make sure that there are no DataStage process running, jobs running and queued on the cordoned node before node upgrade or restart. 

Learn more about Enabling multiple conductor (PX runtime) pods in DataStage at https://www.ibm.com/docs/en/software-hub/5.2.x?topic=resources-enabling-multiple-conductor-pods.


