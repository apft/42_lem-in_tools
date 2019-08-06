# Tools for the lem-in project

* [*check_invalid_map.sh*](#1-check_invalid_mapsh)
* [*checker.sh*](#2-checkersh)
* [*comparator.sh*](#3-comparatorsh)
* [*generator*](#4-generator)
* [*map_edit*](#5-map_edit)

### 1. check_invalid_map.sh
Script that checks how your lem-in handles different invalid maps
```
./check_invalid_map.sh exec

	exec   path to your executable
```

This script run a set of unit tests with invalid maps.
The maps are stored in _maps/invalid_ and the script read the `data_error.txt`
file to run each test.  

To add new tests, follow the following syntax :
```
(1) test name ; (2) file_name
```
* (1) name of the test to display while running the script
* (2) name of the file with the map, this file should be stored under `maps/invalid`


### 2. checker.sh
A script to check your *lem-in* output.
Takes  the path to your executable file and a map in arguments
```
Usage:  ./checker.sh [-h] <lem-in> <map>

     -h        print this message and exit
     lem-in    path to your lem-in executable
     map       map to test
```

Assuming your executable file is in the parent directory, the following command
will run the checker on a valid map.
```
./checker.sh ../lem-in maps/valid/map_subject_3
```

Run several checks on your output :

* the output map is equal to the input one (comments included)
* the solution is separated by an empty line from the map output
* each line contains only one ant
* each line contains only one room (except for the 'end' room)
* each output path is valid (ie. a link exists between two rooms when an ant is moving)
* each ant goes through a valid path
* each ant reach the 'end' room

If any of the previous test fails, an explicit error is printed.


### 3. comparator.sh
This script generates a map with the *generator* and analyse the performance of each executable given in argument.

```
./comparator.sh nb_test map_type exec [exec...]

	nb_test   number of map to generate
	map_type  based on *generator* values (flow-one, flow-ten, flow-thousand, big, big-superposition)
	exec      a list of path to each executable to test
```

If the executables are in the same path as the script use a leading "./".

`./comparator.sh 5 big ./lem-in`

##### Timeout
A timeout value is currently hard coded (currently set to 10 seconds). Modify the `TIMEOUT` variable (in seconds) to a more suitable value if needed.


### 4. generator
A binary file compiled for Mac to generate random maps.
Run `./generator --help` for more information

### 5. map_edit

From its creator *vpaladii*

```
Usage: ./map_edit [map_name] | -e map_name [map_name]
field width should be bigger than 0, height should be bigger than 3. If third argument is ommited map will be saved to new_map file.

If -e flag is used editor will open second argument map for editing. If third argument is ommited resulting map will be saved in the same file.

Click on empty cell to create a node. Click on a node to select it.

While selected you can click on another node to create or destroy link between, or click on empty cell to unselect node.

Select node and click on start or end node image in the upper right corner to select start or end.

Close window or click esc to finish editing and write map to file.

There's indicator below start and end nodes which tells you if map is valid.

You can click on mouse right button to see room names.
```


## Authors

by **apion** and **jkettani**

*map\_edit* is a binary file written by [vpaladii](https://github.com/samaelxxi)

*generator* is a binary file provided by 42
