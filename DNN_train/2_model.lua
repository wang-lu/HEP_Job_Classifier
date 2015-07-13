----------------------------------------------------------------------
--
-- It's a good idea to run this script with the interactive mode:
-- $ torch -i 2_model.lua
-- this will give you a Torch interpreter at the end, that you
-- can use to play with the model.
--
-- Clement Farabet
----------------------------------------------------------------------

require 'torch'   -- torch
require 'nn'      -- provides all sorts of trainable modules/layers

----------------------------------------------------------------------
-- parse command line arguments
if not opt then
   print '==> processing options'
   cmd = torch.CmdLine()
   cmd:text()
   cmd:text(' Model Definition')
   cmd:text()
   cmd:text('Options:')
   cmd:option('-model', 'linear', 'type of model to construct: linear | mlp1 | mlp2|mlp3|mlp4|mlp5')
   cmd:text()
   opt = cmd:parse(arg or {})
end

----------------------------------------------------------------------
print '==> define parameters'

-- 6-class problem
noutputs = 6

-- input dimensions
ninputs = 16

-- number of hidden units (for MLP only):
nhiddens = ninputs * 2


----------------------------------------------------------------------
print '==> construct model'

if opt.model == 'linear' then

   -- Simple linear model
   model = nn.Sequential()
   model:add(nn.Linear(ninputs,noutputs))

elseif opt.model == 'mlp1' then

   -- Simple 2-layer neural network, with tanh hidden units
   model = nn.Sequential()
   model:add(nn.Linear(ninputs,nhiddens))
   model:add(nn.Tanh())
   model:add(nn.Linear(nhiddens,noutputs))
elseif opt.model == 'mlp2' then
   model = nn.Sequential()
   -- layer 1
   model:add(nn.Linear(ninputs,nhiddens))
   model:add(nn.Tanh())
   model:add(nn.Linear(nhiddens,nhiddens))

  -- layer 2
   model:add(nn.Tanh())
   model:add(nn.Linear(nhiddens,noutputs))

elseif opt.model == 'mlp3' then
   model = nn.Sequential()
   -- layer 1
   model:add(nn.Linear(ninputs,nhiddens))
   model:add(nn.Tanh())
   model:add(nn.Linear(nhiddens,nhiddens))

  -- layer 2
   model:add(nn.Tanh())
   model:add(nn.Linear(nhiddens,nhiddens))

  -- layer 3
   model:add(nn.Tanh())
   model:add(nn.Linear(nhiddens,noutputs))


elseif opt.model == 'mlp4' then
   model = nn.Sequential()
   -- layer 1
   model:add(nn.Linear(ninputs,nhiddens))
   model:add(nn.Tanh())
   model:add(nn.Linear(nhiddens,nhiddens))

  -- layer 2
   model:add(nn.Tanh())
   model:add(nn.Linear(nhiddens,nhiddens))

  -- layer 3
   model:add(nn.Tanh())
   model:add(nn.Linear(nhiddens,nhiddens))


   --layer 4
   model:add(nn.Tanh())
   model:add(nn.Linear(nhiddens,noutputs))

elseif opt.model == 'mlp5' then
   model = nn.Sequential()
   -- layer 1
   model:add(nn.Linear(ninputs,nhiddens))
   model:add(nn.Tanh())
   model:add(nn.Linear(nhiddens,nhiddens))

  -- layer 2
   model:add(nn.Tanh())
   model:add(nn.Linear(nhiddens,nhiddens))

  -- layer 3
   model:add(nn.Tanh())
   model:add(nn.Linear(nhiddens,nhiddens))


   --layer 4
   model:add(nn.Tanh())
   model:add(nn.Linear(nhiddens,nhiddens))

   --layer 5
   model:add(nn.Tanh())
   model:add(nn.Linear(nhiddens,noutputs))

else

   error('unknown -model')

end

----------------------------------------------------------------------
print '==> here is the model:'
print(model)

----------------------------------------------------------------------
