# Working with Paramsets and Valuesets

Let us start with file to create a parameter set with two value sets.

```
{
	"parameter_set": {
		"description": "",
		"name": "parmSetTest",
		"parameters": [
			{
				"name": "parm1",
				"prompt": "parm1",
				"subtype": "",
				"type": "int64",
				"value": 11
			},
			{
				"name": "parm11",
				"prompt": "parm11",
				"subtype": "",
				"type": "string",
				"value": "seqFileN10"
			}
		],
		"value_sets": [
			{
				"name": "vset2",
				"values": [
					{
						"name": "parm1",
						"value": 12
					},
					{
						"name": "parm11",
						"value": "test22"
					}
				]
			},
			{
				"name": "ValSet1",
				"values": [
					{
						"name": "parm1",
						"value": 11
					},
					{
						"name": "parm11",
						"value": "seqFileN10"
					}
				]
			}
		]
	}
}
```

Let us create a parameter set using `dsjob` plugin.

```
$ cpdctl dsjob create-paramset -p dsjob -n paramSetTest -f resources/paramset1.json
```

Check the created parameter set

```
$ cpdctl dsjob get-paramset -p dsjob -n parmSetTest --output json
{
    "parameter_set": {
        "description": "",
        "name": "parmSetTest",
        "parameters": [
            {
                "name": "parm1",
                "prompt": "parm1",
                "subtype": "",
                "type": "int64",
                "value": 11
            },
            {
                "name": "parm11",
                "prompt": "parm11",
                "subtype": "",
                "type": "string",
                "value": "seqFileN10"
            }
        ],
        "value_sets": [
   ...
   ...
```


### Update the Param Set Default Values
Current default values are `11`, `setFileN10` for the two parameters in the set parm1 and parm11 respectively.
We can update the values using commandline to new values `22` and `seqFile22` respectively

```
$ cpdctl dsjob update-paramset -p dsjob -n parmSetTest --param int64:parm1:22 --param string:parm11:seqFile22
...
ParameterSet updated for Paramset ID:  f11c5c4f-f491-416e-aa88-15b793c8b403

Status code = 0
```

Now check the parameter set to see that indeed the parameter values are updated. It is required that type should be given when updating the parameter in a parameter set. Valid types supported are `int64, sfloat, string, list, time, timestamp, date, path`.

```
$ cpdctl dsjob get-paramset -p dsjob -n parmSetTest --output json
{
    "parameter_set": {
        "description": "",
        "name": "parmSetTest",
        "parameters": [
            {
                "name": "parm1",
                "prompt": "parm1",
                "subtype": "",
                "type": "int64",
                "value": 22
            },
            {
                "name": "parm11",
                "prompt": "parm11",
                "subtype": "",
                "type": "string",
                "value": "seqFile22"
            }
        ],
        "value_sets": [
...
...
```

We can also do the same from a file and update the parameter set default values
We have a json file to create parameter set values 

```
{
    "parameter_set": {
        "description": "New Description",
        "name": "parmSetTest",
        "parameters": [
            {
                "name": "parm1",
                "prompt": "new prompt parm1",
                "subtype": "",
                "type": "int64",
                "value": 333
            },
            {
                "name": "parm11",
                "prompt": "new prompt parm11",
                "subtype": "",
                "type": "string",
                "value": "seqFile3333"
            }
        ],
    }
}
```
Let us apply this file 

```
$ cpdctl dsjob update-paramset -p dsjob -n parmSetTest -f paramset1.json 
ParameterSet updated for Paramset ID:  f11c5c4f-f491-416e-aa88-15b793c8b403

Status code = 0
```

Query the paramset to check the values

```
$ cpdctl dsjob get-paramset -p dsjob -n parmSetTest --output json
{
    "parameter_set": {
        "description": "",
        "name": "parmSetTest",
        "parameters": [
            {
                "name": "parm1",
                "prompt": "new prompt parm1",
                "subtype": "",
                "type": "int64",
                "value": 333
            },
            {
                "name": "parm11",
                "prompt": "new prompt parm11",
                "subtype": "",
                "type": "string",
                "value": "seqFile3333"
            }
        ],

...
...
```

We can update just one parameter in a parameter set and can only have json with what we want to change. Let us look at json file, this file only updates one parameter `parm11` with a new prompt and value. We also want to updated the `description of the parameter set itself.

```
{
    "parameter_set": {
        "description": "Another description"
        "name": "parmSetTest",
        "parameters": [
            {
                "name": "parm11",
                "prompt": "another prompt parm11",
                "value": "seqFile4444444"
            }
        ],
    }
}
```

Now take a look at the parameter set

```
$ cpdctl dsjob update-paramset -p dsjob -n parmSetTest -f paramset2.json 
...
ParameterSet updated for Paramset ID:  f11c5c4f-f491-416e-aa88-15b793c8b403

Status code = 0

$ cpdctl dsjob get-paramset -p dsjob -n parmSetTest --output json
{
    "parameter_set": {
        "description": "Another description",
        "name": "parmSetTest",
        "parameters": [
            {
                "name": "parm1",
                "prompt": "new prompt parm1",
                "subtype": "",
                "type": "int64",
                "value": 333
            },
            {
                "name": "parm11",
                "prompt": "another prompt parm11",
                "subtype": "",
                "type": "string",
                "value": "seqFile4444444"
            }
        ],
        ...
        ...
```


### Updating Value Set in a ParameterSet

Let us now update the value set `vset2` to new values, to accomplish this from a file, we create a file that represent new value set `vset2` as shown below
```
{
	"name": "vset2",
	"values": [
		{
			"name": "parm1",
			"value": "2222"
		},
		{
			"name": "parm11",
			"value": "test2222"
		}
	]
}
```

Before we update this value set let us get the value set to check...

```
$ cpdctl dsjob get-paramset-valueset -p dsjob --paramset parmSetTest -n vset2 --output json

{
    "name": "vset2",
    "values": [
        {
            "name": "parm1",
            "value": 12
        },
        {
            "name": "parm11",
            "value": "test22"
        }
    ]
}

Status code = 0

```

Now run update command to change vset2 using the definition from the file above

```
$ cpdctl dsjob update-paramset-valueset -p dsjob --paramset parmSetTest -n vset2 -f resources/valueset2.json 
...
ValueSet Updated for Paramset ID:  f11c5c4f-f491-416e-aa88-15b793c8b403

Status code = 0
```

The value set is updated using the definition from the file above.
Let us query the valueset now

```
$ cpdctl dsjob get-paramset-valueset -p dsjob --paramset parmSetTest -n vset2 --output json
{
    "name": "vset2",
    "values": [
        {
            "name": "parm1",
            "value": "2222"
        },
        {
            "name": "parm11",
            "value": "test2222"
        }
    ]
}

Status code = 0
```

Let us now update the second value set from command line

```
$ cpdctl dsjob update-paramset-valueset -p dsjob --paramset parmSetTest -n ValSet1 --value parm1=888 --value parm11=seqFile888
...
ValueSet Updated for Paramset ID:  f11c5c4f-f491-416e-aa88-15b793c8b403

Status code = 0
```

Noew check to see if the values are updated

```
$ cpdctl dsjob get-paramset-valueset -p dsjob --paramset parmSetTest -n ValSet1 --output json
{
    "name": "ValSet1",
    "values": [
        {
            "name": "parm1",
            "value": 888
        },
        {
            "name": "parm11",
            "value": "seqFile888"
        }
    ]
}

Status code = 0
```


