package com.pdftron.reactnative.nativeviews;

import android.graphics.PointF;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.FragmentActivity;

import com.pdftron.pdf.controls.PdfViewCtrlTabFragment;
import com.pdftron.pdf.tools.ToolManager;
import com.pdftron.pdf.utils.AppUtils;
import com.pdftron.pdf.utils.ViewerUtils;

public class RNPdfViewCtrlTabFragment extends PdfViewCtrlTabFragment {

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        try {
            AppUtils.initializePDFNetApplication(getContext().getApplicationContext(), "");
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return super.onCreateView(inflater, container, savedInstanceState);
    }

    @Override
    public void imageStamperSelected(PointF targetPoint) {
        // in react native, intent must be sent from the activity
        // to be able to receive by the activity
        FragmentActivity activity = getActivity();
        if (null == activity) {
            return;
        }
        this.mImageCreationMode = ToolManager.ToolMode.STAMPER;
        this.mAnnotTargetPoint = targetPoint;
        this.mOutputFileUri = ViewerUtils.openImageIntent(activity);
    }

    @Override
    public void imageSignatureSelected(PointF targetPoint, int targetPage, Long widget) {
        // in react native, intent must be sent from the activity
        // to be able to receive by the activity
        FragmentActivity activity = getActivity();
        if (null == activity) {
            return;
        }
        mImageCreationMode = ToolManager.ToolMode.SIGNATURE;
        mAnnotTargetPoint = targetPoint;
        mAnnotTargetPage = targetPage;
        mTargetWidget = widget;
        mOutputFileUri = ViewerUtils.openImageIntent(activity);
    }

    @Override
    public void attachFileSelected(PointF targetPoint) {
        // in react native, intent must be sent from the activity
        // to be able to receive by the activity
        FragmentActivity activity = getActivity();
        if (null == activity) {
            return;
        }
        mAnnotTargetPoint = targetPoint;
        ViewerUtils.openFileIntent(activity);
    }
}
