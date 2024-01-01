import torch
import torch.nn as nn
import AnalysisDataBase as adb
import torch.nn.functional as F
from torch.optim import Adam


# super parameters
DEVIDE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
DROPOUT = 0.5
HIDDEN_SIZE = 1024
LEARNING_RATE = 1e-3
EPOCHS = 3

# image classification network
# hand write number image classification network (0 ~ 9)
class Model(nn.Module):
    def __init__(self, input_size, output_size,DropOut=DROPOUT,HiddenSize=HIDDEN_SIZE):
        super(Model,self).__init__()
        self.input_size = input_size
        self.output_size = output_size
        self.hidden_size = HiddenSize
        self.dropout = DropOut
        self.fc1 = nn.Linear(input_size, HiddenSize) # input_size = 28*28 = 784
        self.fc2 = nn.Linear(HiddenSize, HiddenSize)
        self.fc3 = nn.Linear(HiddenSize, output_size) # output_size = 10, value : (0-9)
        self.initialize()

    def forward(self, x):
        x = F.relu(self.fc1(x)) # activation function for hidden layer
        x = F.relu(self.fc2(x))
        x = F.dropout(x, p=self.dropout, training=self.training) # dropout layer
        x = self.fc3(x) # linear output
        return x

    def initialize(self):
        for m in self.modules():
            if isinstance(m, nn.Linear):
                nn.init.normal_(m.weight.data)  # normal: mean=0, std=1