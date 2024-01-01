import Model
import AnalysisDataBase as adb
import torch
from torch.optim import Adam
from torch.utils.tensorboard import SummaryWriter

MODEL_SAVE_PATH = 'Model/HandWriteNumberImageRecognition.pth'

if __name__ == "__main__":
    # Get the train data
    train_images, train_labels, test_images, test_labels, train_nums, test_nums = adb.get_data()
    input_size = 28 * 28 # 28*28 pixels
    output_size = 10 # 0-9 digits
    model = Model.Model(input_size, output_size) # create the model
    model.to(Model.DEVIDE) # move the model to GPU if available
    optimizer = Adam(model.parameters(), lr=Model.LEARNING_RATE) # create the optimizer
    writer = SummaryWriter('Log')
    scheduler = torch.optim.lr_scheduler.ExponentialLR(optimizer, gamma=0.95) # adjust learning rate

    # train
    step = 0
    model = model.train()
    for epoch in range(Model.EPOCHS):
        for i in range(train_nums):
            step += 1
            images = torch.Tensor(train_images[i]) # (28, 28)
            images = images.view(28*28)# (28 * 28)
            # reshape input to (1,28*28)
            images = torch.unsqueeze(images, 0) # (1, 28*28)
            images = images.to(Model.DEVIDE)
            labels = torch.LongTensor([train_labels[i]]) # (1)
            # reshape label to (1,1)
            # labels = torch.unsqueeze(labels, 0) # (1, 1)
            labels = labels.to(Model.DEVIDE)
            optimizer.zero_grad()

            # forward
            output = model(images)
            loss = Model.F.cross_entropy(output, labels)
            # backward
            loss.backward()
            optimizer.step()
            # adjust learning rate
            if step % 1000 == 0:
                scheduler.step()

            # print loss
            if step % 100 == 0:
                print('Epoch: ', epoch + 1, '| train loss: %.4f' % loss.item(),end='')
                print(' | step: ', step,end='')
                print(' | expected: ', labels.item(),' | get: ', torch.argmax(output, dim=1).item())
                writer.add_scalar('train loss', loss.item(), step)

    print()
    print('Finished Training')
    print(" ============================================================================================== ")
    print(" ============================================================================================== ")
    # test
    model = model.eval()
    with torch.no_grad():
        correct = 0
        s = 0
        for i in range(test_nums):
            s += 1
            images = torch.Tensor(train_images[i])  # (28, 28)
            images = images.view(28 * 28)  # (28 * 28)
            # reshape input to (1,28*28)
            images = torch.unsqueeze(images, 0)  # (1, 28*28)
            images = images.to(Model.DEVIDE)
            labels = torch.LongTensor([train_labels[i]])  # (1)
            # reshape label to (1,1)
            # labels = torch.unsqueeze(labels, 0) # (1, 1)
            labels = labels.to(Model.DEVIDE)

            output = model(images)

            if torch.argmax(output, dim=1).item() == labels.item():
                correct += 1

            if s % 100 == 0:
                print('step: ', s, end='')
                print(' | correct: ', correct, end='')
                print(' | expected: ', labels.item(), ' | get: ', torch.argmax(output, dim=1).item())

        print('Accuracy: ', correct / test_nums)

    # save the model
    torch.save(model, MODEL_SAVE_PATH)