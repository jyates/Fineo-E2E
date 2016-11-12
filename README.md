# Fineo-E2E

## Setup

### Requirements
 1. https://rvm.io/
 2. Download a release of spark into ext/ and connect the symlink. (Recommended)[http://www.apache.org/dyn/closer.lua/spark/spark-1.6.2/spark-1.6.2-bin-hadoop2.6.tgz]

 ## Usage

 Kick off tests normally with the ```test.sh``` script. If you have all the other Fineo projects installed in the directory above the current directory (and built with `-Ddeploy`) then this should just work.

 ### Standalone instance

 You might want a standalone instance of the readerator/drill/dynamo with a little bit of data in it. In that case, run:

 ```
 $ ./test.sh  --pattern `pwd`/standalone/*rb
 ```

 When it is ready, the console will display the necessary connection information.
