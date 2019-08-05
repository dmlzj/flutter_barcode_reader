//
// Created by Matthew Smith on 11/7/17.
//

#import "BarcodeScannerViewController.h"
#import <MTBBarcodeScanner/MTBBarcodeScanner.h>
#import "ScannerOverlay.h"

@implementation BarcodeScannerViewController {
    BOOL isFromAlbum;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"扫一扫";
    self.previewView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_previewView];
    [self.view addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"V:[previewView]"
                                options:NSLayoutFormatAlignAllBottom
                                metrics:nil
                                  views:@{@"previewView": _previewView}]];
    [self.view addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"H:[previewView]"
                                options:NSLayoutFormatAlignAllBottom
                                metrics:nil
                                  views:@{@"previewView": _previewView}]];
  self.scanRect = [[ScannerOverlay alloc] initWithFrame:self.view.bounds];
  self.scanRect.translatesAutoresizingMaskIntoConstraints = NO;
  self.scanRect.backgroundColor = UIColor.clearColor;
  [self.view addSubview:_scanRect];
  [self.view addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:@"V:[scanRect]"
                             options:NSLayoutFormatAlignAllBottom
                             metrics:nil
                             views:@{@"scanRect": _scanRect}]];
  [self.view addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:@"H:[scanRect]"
                             options:NSLayoutFormatAlignAllBottom
                             metrics:nil
                             views:@{@"scanRect": _scanRect}]];
  [_scanRect startAnimating];
    self.scanner = [[MTBBarcodeScanner alloc] initWithPreviewView:_previewView];
    
    [self creatBarButton];
}

- (void)creatBarButton
{
    UIButton * backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, 0, 44, 44);
    [backBtn setImage:[UIImage imageNamed:@"backbutton"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * leftItem = [[UIBarButtonItem alloc]initWithCustomView:backBtn];
    UIBarButtonItem * leftflexSpacer = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    leftflexSpacer.width = -15;
    [self.navigationItem setLeftBarButtonItems:[NSArray arrayWithObjects:leftflexSpacer,leftItem,nil]];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"相册"                                style:UIBarButtonItemStylePlain target:self action:@selector(toggle)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor blackColor];
}
//打开相册
- (void)toggle{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

// UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    
    UIImage *pickedImage = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    CIImage *detectImage = [CIImage imageWithData:UIImagePNGRepresentation(pickedImage)];
    
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyLow}];
    CIQRCodeFeature *feature = (CIQRCodeFeature *)[detector featuresInImage:detectImage options:nil].firstObject;
     [picker dismissViewControllerAnimated:YES completion:nil];
    if (feature.messageString) {
        isFromAlbum = YES;
        [self.scanner stopScanning];
        [self.delegate barcodeScannerViewController:self didScanBarcodeWithResult:feature.messageString];
        [self dismissViewControllerAnimated:NO completion:nil];
    }else{
        isFromAlbum = YES;
        [self.scanner stopScanning];
        [self.delegate barcodeScannerViewController:self didFailWithErrorCode:@"未识别出二维码"];
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!isFromAlbum) {
        if (self.scanner.isScanning) {
            [self.scanner stopScanning];
        }
         [_scanRect startAnimating];
        [MTBBarcodeScanner requestCameraPermissionWithSuccess:^(BOOL success) {
            if (success) {
                [self startScan];
            } else {
                [self.delegate barcodeScannerViewController:self didFailWithErrorCode:@"PERMISSION_NOT_GRANTED"];
                [self dismissViewControllerAnimated:NO completion:nil];
            }
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.scanner stopScanning];
    [super viewWillDisappear:animated];
}

- (void)startScan {
    NSError *error;
    [self.scanner startScanningWithResultBlock:^(NSArray<AVMetadataMachineReadableCodeObject *> *codes) {
        [self.scanner stopScanning];
         AVMetadataMachineReadableCodeObject *code = codes.firstObject;
        if (code) {
            [self.delegate barcodeScannerViewController:self didScanBarcodeWithResult:code.stringValue];
            [self dismissViewControllerAnimated:NO completion:nil];
        }
    } error:&error];
}

- (void)cancel {
    [self.delegate barcodeScannerViewController:self didFailWithErrorCode:@"USER_CANCELED"];
    [self dismissViewControllerAnimated:true completion:nil];
}

//- (void)updateFlashButton {
//    if (!self.hasTorch) {
//        return;
//    }
//    if (self.isFlashOn) {
//        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Flash Off"
//                                                                                  style:UIBarButtonItemStylePlain
//                                                                                 target:self action:@selector(toggle)];
//    } else {
//        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Flash On"
//                                                                                  style:UIBarButtonItemStylePlain
//                                                                                 target:self action:@selector(toggle)];
//    }
//}

//- (void)toggle {
//    [self toggleFlash:!self.isFlashOn];
//    [self updateFlashButton];
//}

- (BOOL)isFlashOn {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        return device.torchMode == AVCaptureFlashModeOn || device.torchMode == AVCaptureTorchModeOn;
    }
    return NO;
}

- (BOOL)hasTorch {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        return device.hasTorch;
    }
    return false;
}

- (void)toggleFlash:(BOOL)on {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!device) return;

    NSError *err;
    if (device.hasFlash && device.hasTorch) {
        [device lockForConfiguration:&err];
        if (err != nil) return;
        if (on) {
            device.flashMode = AVCaptureFlashModeOn;
            device.torchMode = AVCaptureTorchModeOn;
        } else {
            device.flashMode = AVCaptureFlashModeOff;
            device.torchMode = AVCaptureTorchModeOff;
        }
        [device unlockForConfiguration];
    }
}


@end
