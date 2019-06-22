# Tools for the lem-in project

* *checker.sh*
* *comparator.sh*
* *generator*
* *map_edit*

#### 1. checker.sh
A script to check your *lem-in* output.
Takes  the path to your executable file and a map in arguments

./checker.sh exec map

Run several checks on your output :

1. the output map is equal to the input one (comments included)
2. the solution is separated by an empty line from the map output
3. each line contains only one ant
4. each line contains only one room (except for the 'end' room)
5. each output path is valid (ie. a link exists between two rooms when an ant is moving)
6. each ant goes through a valid path

If any of the previous test fails, an explicit error is printed and the script ends.


#### 2. comparator.sh
This script generates a map with the *generator* and analyse the performance of each executable given in argument.

```
./comparator nb_test map_type exec [exec...]

	- nb_test   number of map to generate
	- map_type  based on *generator* values (flow-one, flow-ten, flow-thousand, big, big-superposition)
	- exec      a list of path to each executable to test
```

##### Timeout
A timeout value is currently hard coded (currently set to 10 seconds). Modify the `TIMEOUT` variable (in seconds) to a more suitable value if needed.


#### 3. generator
A binary file compiled for Mac to generate random maps.
Run `./generator --help` for more information

#### 4. map_edit

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


## Issues

If you encounter any issue, you can contact me by email: apion(at)student[dot]42[dot]fr


## Authors

by **apion** and **jkettani**

*map\_edit* is a binary file written by [vpaladii](https://github.com/samaelxxi)

*generator* is a binary file provided by 42
