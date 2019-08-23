package com.apptreesoftware.barcodescan;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Log;
import android.view.View;
import android.widget.Toast;


import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.google.zxing.Result;
import com.shengyun.barcodescan.R;

import me.dm7.barcodescanner.zxing.ZXingScannerView;


public class Scanner_Activity extends Activity {
//    private boolean mFlash;
    private ZXingScannerView mScannerView;
    final int REQUEST_TAKE_PHOTO_CAMERA_PERMISSION = 100;
    final int REQUEST_PICK_IMAGE = 300;

    private ZXingScannerView.ResultHandler mResultHandler = new ZXingScannerView.ResultHandler() {
        @Override
        public void handleResult(Result result) {
            mScannerView.resumeCameraPreview(mResultHandler); //重新进入扫描二维码

//            Toast.makeText(getApplicationContext(), "内容=" + result.getText() + ",格式=" + result.getBarcodeFormat().toString(), Toast.LENGTH_SHORT).show();
            Intent intent = new Intent();
            intent.putExtra("SCAN_RESULT", result.getText());
            setResult(Activity.RESULT_OK, intent);
            finish();
        }
    };

    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);
        setContentView(R.layout.activity_scaling_scanner);

        mScannerView = (ZXingScannerView) findViewById(R.id.scannerView);
        mScannerView.setAutoFocus(true);
        mScannerView.setAspectTolerance(0.5f);
        mScannerView.setResultHandler(mResultHandler);
        if (!requestCameraAccessIfNecessary()) {
            mScannerView.startCamera();
        }

        findViewById(R.id.back).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });

        findViewById(R.id.photo).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                //打开相册
//                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT) {
//                    startActivityForResult(new Intent(Intent.ACTION_GET_CONTENT).setType("image/*"),
//                            REQUEST_PICK_IMAGE);
//                } else {
//                    Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
//                    intent.addCategory(Intent.CATEGORY_OPENABLE);
//                    intent.setType("image/*");
//                    startActivityForResult(intent, REQUEST_PICK_IMAGE);
//                }
                Intent intent = new Intent();
                intent.setAction(Intent.ACTION_PICK);
                intent.setType("image/*");
                startActivityForResult(intent, REQUEST_PICK_IMAGE);
            }
        });

//        findViewById(R.id.light).setOnClickListener(new View.OnClickListener() {
//            @Override
//            public void onClick(View view) {
//                toggleFlash();
//            }
//        });
    }


    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (resultCode == Activity.RESULT_OK) {
            switch (requestCode){
                case REQUEST_PICK_IMAGE:


                    if (data != null) {
                        Uri uri = data.getData();
                        try {
                            CodeUtils.analyzeBitmap(ImageUtil.getImageAbsolutePath(this, uri), new CodeUtils.AnalyzeCallback() {
                                @Override
                                public void onAnalyzeSuccess(Bitmap mBitmap, String result) {
//                                    Toast.makeText(Scanner_Activity.this, "解析结果:" + result, Toast.LENGTH_LONG).show();
                                    Intent intent = new Intent();
                                    intent.putExtra("SCAN_RESULT", result);
                                    setResult(Activity.RESULT_OK, intent);
                                    finish();
                                }

                                @Override
                                public void onAnalyzeFailed() {
                                    Toast.makeText(Scanner_Activity.this, "无法识别", Toast.LENGTH_LONG).show();
                                    finish();
                                }
                            });
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    }


                    break;
            }
        }

    }

    private boolean requestCameraAccessIfNecessary() {
        String[] array = {Manifest.permission.CAMERA,Manifest.permission.READ_EXTERNAL_STORAGE,Manifest.permission.WRITE_EXTERNAL_STORAGE};
        if (ContextCompat
                .checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED
        && ContextCompat
                .checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED
        && ContextCompat
                .checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {

            ActivityCompat.requestPermissions(this, array,
                    REQUEST_TAKE_PHOTO_CAMERA_PERMISSION);
            return true;
        }
        return false;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        switch (requestCode) {
            case REQUEST_TAKE_PHOTO_CAMERA_PERMISSION:
                if (PermissionUtils.verifyPermissions(grantResults)) {
                    mScannerView.startCamera();
                } else {
                    finishWithError("PERMISSION_NOT_GRANTED");
                }
            break;
            default:
                super.onRequestPermissionsResult(requestCode, permissions, grantResults);
            break;
        }
    }

    void finishWithError(String errorCode) {
        Intent intent = new Intent();
        intent.putExtra("ERROR_CODE", errorCode);
        setResult(Activity.RESULT_CANCELED, intent);
        finish();
    }

    @Override
    public void onResume() {
        super.onResume();
        mScannerView.setResultHandler(mResultHandler);
        mScannerView.startCamera();
    }

    @Override
    public void onPause() {
        super.onPause();
        mScannerView.stopCamera();
    }

//    private void toggleFlash() {
//        mFlash = !mFlash;
//        mScannerView.setFlash(mFlash);
//    }
}

class PermissionUtils {

        /**
         * Check that all given permissions have been granted by verifying that each entry in the
         * given array is of the value [PackageManager.PERMISSION_GRANTED].
         */
        static boolean verifyPermissions(int[] grantResults) {
        // At least one result must be checked.
            if (grantResults.length < 1) {
                return false;
            }

            // Verify that each required permission has been granted, otherwise return false.
            for (int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    return false;
                }
            }
            return true;
        }
}
