import os
import numpy as np
import struct
import shutil
from PIL import Image


# idx3: 3 dimensions, idx1: 1 dimension
# train-images
train_images_idx3_ubyte_file = 'DataBase/train-images.idx3-ubyte'
# train-labels
train_labels_idx1_ubyte_file = 'DataBase/train-labels.idx1-ubyte'

# test-images
test_images_idx3_ubyte_file = 'DataBase/t10k-images.idx3-ubyte'
# test-labels
test_labels_idx1_ubyte_file = 'DataBase/t10k-labels.idx1-ubyte'

# train-images-ouput-path
train_images_output_dir = 'DataBase/train-images'
# test-images-ouput-path
test_images_output_dir = 'DataBase/test-images'

# analyze idx3 file
def decode_idx3_ubyte(idx3_ubyte_file):
    """
    analyze idx3 file
    :param idx3_ubyte_file: file path
    :return: data set, number of images
    """

    bin_data = open(idx3_ubyte_file, 'rb').read()

    # analyze file header, magic number, number of images, height and width of each image, here we don't store magic number, so the first return value of struct.unpack_from is _
    offset = 0
    fmt_header = '>iiii'# i represents integer, four i represents four integers, > is added to solve the alignment problem
    #struct.unpack_from(fmt=,buffer=,offfset=) this function can read the content of the buffer from the offset=numb position according to the specified format fmt='somenformat'. The return value is a corresponding tuple tuple
    _, num_images, num_rows, num_cols = struct.unpack_from(fmt_header, bin_data, offset)
    print('image : %d, size: %d*%d' % (num_images, num_rows, num_cols))


    image_size = num_rows * num_cols
    offset += struct.calcsize(fmt_header)#calcsize(fmt) -> integer  cauculate the size of the fmt
    fmt_image = '>' + str(image_size) + 'B'# get the byte format of the image
    images = np.empty((num_images, num_rows, num_cols))
    for i in range(num_images):
        images[i] = np.array(struct.unpack_from(fmt_image, bin_data, offset)).reshape((num_rows, num_cols))
        offset += struct.calcsize(fmt_image)
    return images,num_images

# analyze idx1 file
def decode_idx1_ubyte(idx1_ubyte_file):
    """
    analyze idx1 file
    :param idx1_ubyte_file: file path
    :return: data set
    """

    bin_data = open(idx1_ubyte_file, 'rb').read()

    # analyze file header, magic number and number of labels, here we don't store magic number, so the first return value of struct.unpack_from is _
    offset = 0
    fmt_header = '>ii'
    _, num_images = struct.unpack_from(fmt_header, bin_data, offset)
    print('image : %d' % (num_images))


    offset += struct.calcsize(fmt_header)
    fmt_image = '>B'
    labels = np.empty(num_images)
    for i in range(num_images):
        labels[i] = struct.unpack_from(fmt_image, bin_data, offset)[0]
        offset += struct.calcsize(fmt_image)
    return labels

# get train images
def load_train_images(idx_ubyte_file=train_images_idx3_ubyte_file):
    """
    TRAINING SET IMAGE FILE (train-images-idx3-ubyte):
    [offset] [type]          [value]          [description]
    0000     32 bit integer  0x00000803(2051) magic number
    0004     32 bit integer  60000            number of images
    0008     32 bit integer  28               number of rows
    0012     32 bit integer  28               number of columns
    0016     unsigned byte   ??               pixel
    0017     unsigned byte   ??               pixel
    ........
    xxxx     unsigned byte   ??               pixel
    Pixels are organized row-wise. Pixel values are 0 to 255. 0 means background (white), 255 means foreground (black).

    :param idx_ubyte_file: file path
    :return: n*row*col(np.array), n is the number of images
    """
    return decode_idx3_ubyte(idx_ubyte_file)

# get train labels
def load_train_labels(idx_ubyte_file=train_labels_idx1_ubyte_file):
    """
    TRAINING SET LABEL FILE (train-labels-idx1-ubyte):
    [offset] [type]          [value]          [description]
    0000     32 bit integer  0x00000801(2049) magic number (MSB first)
    0004     32 bit integer  60000            number of items
    0008     unsigned byte   ??               label
    0009     unsigned byte   ??               label
    ........
    xxxx     unsigned byte   ??               label
    The labels values are 0 to 9.

    :param idx_ubyte_file: file path
    :return: n*1(np.array), n is the number of images
    """
    return decode_idx1_ubyte(idx_ubyte_file)

# get test images
def load_test_images(idx_ubyte_file=test_images_idx3_ubyte_file):
    """
    TEST SET IMAGE FILE (t10k-images-idx3-ubyte):
    [offset] [type]          [value]          [description]
    0000     32 bit integer  0x00000803(2051) magic number
    0004     32 bit integer  10000            number of images
    0008     32 bit integer  28               number of rows
    0012     32 bit integer  28               number of columns
    0016     unsigned byte   ??               pixel
    0017     unsigned byte   ??               pixel
    ........
    xxxx     unsigned byte   ??               pixel
    Pixels are organized row-wise. Pixel values are 0 to 255. 0 means background (white), 255 means foreground (black).

    :param idx_ubyte_file: file path
    :return: n*row*col(np.array), n is the number of images
    """
    return decode_idx3_ubyte(idx_ubyte_file)

# get test labels
def load_test_labels(idx_ubyte_file=test_labels_idx1_ubyte_file):
    """
    TEST SET LABEL FILE (t10k-labels-idx1-ubyte):
    [offset] [type]          [value]          [description]
    0000     32 bit integer  0x00000801(2049) magic number (MSB first)
    0004     32 bit integer  10000            number of items
    0008     unsigned byte   ??               label
    0009     unsigned byte   ??               label
    ........
    xxxx     unsigned byte   ??               label
    The labels values are 0 to 9.

    :param idx_ubyte_file: file path
    :return: n*1(np.array)，n is the number of images
    """
    return decode_idx1_ubyte(idx_ubyte_file)

# output Images
def Output_train_images(path,images,labels):
    if os.path.exists(path):
        shutil.rmtree(path)
    if not os.path.exists(path):
        os.mkdir(path)
    for i,j in enumerate(labels):
        t = images[i]
        t = t.astype(np.uint8)
        img = Image.fromarray(t)
        file_name = path + os.sep+ str(j) + '_' + str(i)+ '.png'
        img.save(file_name)



def get_data():
    train_images,train_nums = load_train_images()
    train_labels = load_train_labels()
    test_images,test_nums = load_test_images()
    test_labels = load_test_labels()

    return train_images,train_labels,test_images,test_labels,train_nums,test_nums

if __name__ == '__main__':
    get_data()
