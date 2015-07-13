----------------------------------------------------------------------

require 'torch'   -- torch
require 'nn'      -- provides a normalization operator

----------------------------------------------------------------------
-- parse command line arguments
if not opt then
   print '==> processing options'
   cmd = torch.CmdLine()
   cmd:text()
   cmd:text('Dataset Preprocessing')
   cmd:text()
   cmd:text('Options:')
   cmd:option('-size', '10', 'percentage of data used, value from 1 to 10')
   cmd:text()
   opt = cmd:parse(arg or {})
end


----------------------------------------------------------------------
-- training/test size

trsize = (193140*opt.size)/10-10 
tesize = (64380*opt.size)/10-10 
-- here tesize means validation 

print(string.format("using %d trainning data,%d valiation data\n", trsize,tesize)); 



----------------------------------------------------------------------
print '==> loading dataset'

train_file='train_data.txt'

require 'csvigo'
loaded = csvigo.load{path=train_file,header=false,separator=" "}
featuresize=16
rawoutputs=torch.Tensor(loaded.var_17)
mysize=(#rawoutputs)[1]
print ("mysize is " .. mysize);
if mysize < (trsize+tesize)
then
	print("sample not enough" );
	os.exit()
end
shuffle = torch.randperm(mysize)
mydata=torch.Tensor(mysize,featuresize)
rawdata=torch.Tensor(mysize,featuresize)
myoutputs=torch.Tensor(mysize)

for j=1,featuresize
do
        key='var_'..j
        tmp=torch.Tensor(loaded[key])
        rawdata[{ {},j }]=tmp
end

print '==> preprocessing data'

--1. shuffle the data
for i=1,mysize
do
	index=shuffle[i]
	mydata[{ i,{1,featuresize} }]=rawdata[{ index,{1,featuresize} }]
	myoutputs[{i}]=rawoutputs[{index}]
end

-- get squareroot of data
--print (mydata[{{1},{1,featuresize}}])
mydata[{{},{1,featuresize}}]=mydata[{{},{1,featuresize}}]:sqrt()
--print (mydata[{{1},{1,featuresize}}])


trainData = {
   data=mydata[{ {1,trsize},{} }],
   labels=myoutputs[{ {1,trsize} }],
   size = function() return trsize end
}
testData = {
	data =mydata[{ {trsize+1,trsize+tesize},{} }],
  	labels = myoutputs[{ {trsize+1,trsize+tesize} }],
   	size = function() return tesize end
}
trainData.data = trainData.data:float()
testData.data = testData.data:float()

----------------------------------------------------------------------


-- nominization of data
--2. norminization of each feature

mean={}
std={}
for i=1,featuresize 
do
   -- normalize each column globally:
   mean[i] = trainData.data[{ {},i }]:mean()
   std[i] = trainData.data[{ {},i }]:std()
   trainData.data[{ {},i }]:add(-mean[i])
   testData.data[{ {},i }]:add(-mean[i])
   if std[i]>0
   then
   	trainData.data[{ {},i }]:div(std[i])
   	testData.data[{ {},i }]:div(std[i])
   end
end



function summarizeData()
   function p(name,value)
      print(string.format('%20s %f', name, value) )
   end
   for i =1,featuresize
   do
       -- key='min of '..'t['..i..']'
       -- p(key, torch.min(mydata[{ {},i }]))
       -- key='max of '..'t['..i..']'
       -- p(key, torch.max(mydata[{ {},i }]))
        key='mean of '..'t['..i..']'
        p(key, mean[i])
        key='std of '..'t['..i..']'
        p(key, std[i])
   end
end
--summarizeData()
--print (testData.data[{{1},{1,featuresize}}])


