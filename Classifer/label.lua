----------------------------------------------------------------------
-- This script implements a test procedure, to report accuracy
-- on the test data. Nothing fancy here...
--
-- Clement Farabet
----------------------------------------------------------------------

require 'torch'   -- torch
--require 'xlua'    -- xlua provides useful tools, like progress bars
require 'optim'   -- an optimization package, for online and batch methods
require 'nn'
----------------------------------------------------------------------
--print '==> processing options'

cmd = torch.CmdLine()
cmd:text()
cmd:text('IO classifier of HEP jobs')
cmd:text()
cmd:text('Options:')
-- data:
cmd:option('-pattern', '', 'the IO pattern with 13 collumn')
cmd:option('-model', 'linear', 'type of model to construct: linear | mlp | mmlp')
cmd:option('-save', 'results', 'subdirectory to save/log experiments in')
cmd:text()
opt = cmd:parse(arg or {})

--print '==> loading dataset'
if (opt.pattern == '')
then
	print "unknown"
	os.exit()
end

featuresize=16
input=torch.Tensor(featuresize*2)
rawdata=torch.Tensor(featuresize+1)
i=1
sum=0
for token in string.gmatch(opt.pattern, "[^%s]+") do
	rawdata[i]=token	
	i=i+1
end
for i=1,featuresize
do 
	input[i]=torch.sqrt(rawdata[i])
	sum=sum+rawdata[i]
end

for i=featuresize+1,featuresize*2
do
	input[i]=rawdata[i-featuresize]*100/sum
end


local filename = paths.concat(opt.save, 'meanstd')
res=torch.load(filename)
mean=torch.Tensor(featuresize*2)
std=torch.Tensor(featuresize*2)
mean=res[{{},1}]
std=res[{{},2}]



for i=1,featuresize*2
do 
	if (std[i]>0)
	then
		input[i]=(input[i]-mean[i])/std[i]
	else
		input[i]=input[i]-mean[i]
	end
	
end

--print (input)
--print (mean)
--print (std)

local filename = paths.concat(opt.save, 'model.net')
model=torch.load(filename)
--print (model)
--model:add(nn.LogSoftMax())


-- test over test data
--print('==> testing on test set:')
pred = model:forward(input)
--print (pred)
maxi=1
max=pred[1]
for i=2,6
do
	if(pred[i]>max)
	then
		max=pred[i]
		maxi=i
	end
end
if maxi==1
then
	print ("ana")
elseif maxi==2
then
	print ("rec")
elseif maxi==3
then
	print ("sim")
elseif maxi==4
then 	
	print ("cal")
elseif maxi==5
then 
	print ("scan")
elseif maxi==6
then 
	print ("skim")
end

