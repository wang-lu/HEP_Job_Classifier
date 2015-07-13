# A Classifier of High Energy Physics Cluster Jobs #
## Motivation ##

The cluster of [IHEP]( http://www.ihep.ac.cn ) sees tens of thousands of High Energy Physics Computing jobs running everyday. These jobs could be roughly divided into six categories:*Analysis*,*Simulation*,*reconstruction*,*calibration*,*skim*,*scan*. It is always better to make job statistics of job efficiency and requirements for each job category respectively. However, the category( * i.e. type*) information is not necessarily provided by cluster user. Therefore, the job statistic system need a job classifier to generate fine-grained statistics. 

Deep Neural Network [1] is a non-linear machine learning algorithm inspired by the brain. It has properties of scaling to very large datasets and very large feature space, supporting on-line training, capability of feature learning etc. Recently, it has achieved better performance than other state-of-art algorithms in domains of natural language processing [2], computer vision [3], and speech recognition [4]. In high energy physics domain, physicists have started to use DNNs on the problem of exotic particles classification, and encouraging results have been presented [5]. 

## Overview ##

This software classifies High Energy Physics cluster jobs by their IO patterns.

It includes three on-line components:

- IO Agent 
- Data Summary  
- job classifier

and two offline components:

- model trainning
- trainning dataset generator 


## How each Component Work?

### IO Agent 
The `IO Agent` runs on every cluster node. 

It collects the frequencies of 4 IO activities: **READ**,** WRITE**, **SEEK BEFORE READ** and **SEEK BEFORE WRITE**. 

divides each activity into four sub categories by its size: **Very Large** ( 4MB ), **Large** (1 MB - 4 MB),**Middle Size ** ( 4KB -1MB), and **small** ( 0 - 4KB ). *

Then it gets a 16-dimension IO feature for the job classifier as the input.  

It has two versions: 

- `IO_Agent_with_lustre` parse the Lustre IO statistic information under /proc/fs/lustre/llite/*/extent_stats_per_process and /proc/fs/lustre/llite/*/offset_stats [6]. This version works only for clusters which use [Lustre](https://wiki.hpdd.intel.com/display/PUB/HPDD+Wiki+Front+Page) as the main disk file system like IHEP.  

- `IO_Agent_with_SystemTap` collects IO activities on VFS layer by a kernel model compiled by a SystemTap [7]  scipt. It filters and summaries IO activies by process id and file system type. It is better generalized but less tested than the prior. 

IO Agent generates  `pbsid-processid.raw`file and a `pbsid-processid.out` file as the "snapshot" of each probed process under /topdir/date/hostname/ directory. The `.raw` file will be used as a archive of job snapshot, while information in `.out` will be used by rest components in this package. Job efficiency and some static information such as “execuation name”, "user name", pid, pbsid will be also recorded in `.out` file. 

For jobs which has *suspicious* IO  behaviours, IO agents send a realtime alarming mail. 

In the life time of a process, its IO activities will be probed only once after at least 15 miniutes from its beginning. The span of probe by default is 1 minute. 

*Zero sized SEEK will not be counted.

### Data Summary ###

`job_summary/summary.pl` scans new `.out` files under "/topdir/date/". It parses the `.out` file, provide the `job classifer` with IO features as input and then inserts job type information into job statistic database. 
The table of job infomation is defined by `DB/create.sql`.

### Job Classifer ###
Job classifer `label.lua` forwards IO features to the model trained by `Model training component` ,get the output type and passes it back to `summary.pl`. It requires the execuration enviroment of model trainner, therefore, it is deployed on the same machine with model trainner. 

### Model trainning
The Deep Neural Networks model is the central of this package. It is trains DNNs models with [Torch](http://torch.ch). There is a 320'000 rows dataset. (See `trainset.txt` and `testset.txt` under `DNN_train`) . The trainning process includes 5 steps:
1. data process(see `1_data.lua` ), it parses `trainset.txt` and `testset.txt`, permutes the rows and normalizes the columns, the last colummn is an integer of the job type. 
2. model definition(see `2_model.lua`), it defines number of hidden layers, elements of each layer. A softmax layer is added after output layer.
3. loss function definition (see `3_loss.lua`), defines loss function specified by user. 
4. model trainning(see `4_train.lua`), trains model by trainning algorithm specified by user. 
5. test (see `5_test.lua`), outputs the confusion matrix and global precision with a testset.  

mean and standard deviation values of each column after normilization is stored together with the result model. 


the file `doall.lua` will call it step by step. 

### Sample Generator 
 
11. An `sample generator` which leverages the key word information "kindly" appeared in ~10% jobs names  to generate the training set. (As you know, it is difficlut to tag a training set of 10'000 scale manually.)

###  Usage
### IOAgent_with_Lustre
Deploy it on cluster node and calls it with a cronjob. You can **must** sepcify cluster name as input parameter.  for `process_check.pl`. `process_check.pl` need write permission on *topdir*.
`process_check.sh` is an example of `process_check.pl` caller. `match.pl` includes functions used by `process_check.pl`
`process_check.sh` is a exmaple of how to use `process_check.pl`.
*some lines which includes our local configuration infor has been changed. 

### IO Agent_with_SystemTap
Make sure all the cluster nodes has SystemTap installed. 
For each kind of kernel version, compile a kernel module on a system which has kernel-debug and kernel-debug-common installed. 
Compile the module like this:

``` # stap -m ioagent ioagent.stp 
```

Run the ioagent module like this:

``` # staprun ioagent -x yourpid -o youroutput
```

### Data Summary 
Deploy it on a central machine and starts it with a daily crontab. It needs read permission of *topdir* and write permission to the statistic DB. 
The statistic DB is intitialized by `create.sql`

### Job Classifer 
run it :
    ```# th label.lua "803 0 0 0 7 0 0 0 14 0 0 0 2 0 0 0 "
	```

The parameter string  is the 16 dimension IO feature. 

### Model trainning

run it like this:

``` # th doall.lua -model mmlp -save myresult 

It trains a mmlp model defined by `2_model.lua` outputs results in the directory called myresult

run ``` th doall_final.lua --help ``` for more details. 




## References
- [1]	Hinton, G. E., & Salakhutdinov, R. R. (2006). Reducing the dimensionality of data with neural 
networks. Science, 313(5786):504-507.
- [2]	Tomas Mikolov, Kai Chen, Greg Corrado, and Jeffrey Dean. Efficient Estimation of Word
Representations in Vector Space. Proceedings of Workshop at ICLR, 2013.
- [3]	Alex Krizhevsky, Ilya Sutskever, Geoffrey E. Hinton.ImageNet Classification with Deep
Convolutional Neural Networks. NIPS 2012: 1106-1114.
- [4]	Dong Yu, Li Deng, Frank Seide. Large Vocabulary Speech Recognition Using Deep Tensor 
Neural Networks. INTERSPEECH 2012: 6-9. 
- [5]	Baldi, P., Sadowski, P., & Whiteson, D.. Searching for exotic particles in high-energy
physics with deep learning. Nature communications, 5 (2014). 
- [6]	Lustre File Systrem Manual. https://wiki.hpdd.intel.com/display/PUB/Documentation
- [7]	Jacob B, Larson P, Leitao B, et al. SystemTap: instrumenting the Linux kernel for analyzing 
performance and functional problems [J]. IBM Redbook, 2008.



## Credits

### Author
This software was developed and is maintained by Lu Wang at [ Computing Center,Institute of High Energy Physics ](http://it.ihep.ac.cn) (Beijing, China). 

### Acknowledgements

The DNN model is trained on [Torch](http://torch.ch), an Deep Learning platform. 


## License
Copyright 2015 Lu Wang

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


