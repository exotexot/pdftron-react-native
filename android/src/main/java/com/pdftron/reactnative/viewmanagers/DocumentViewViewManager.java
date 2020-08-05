package com.pdftron.reactnative.viewmanagers;

import android.content.Intent;
import android.util.Log;
import android.util.SparseArray;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewGroupManager;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.pdftron.common.PDFNetException;
import com.pdftron.pdf.PDFViewCtrl;
import com.pdftron.pdf.utils.PdfViewCtrlSettingsManager;
import com.pdftron.reactnative.views.DocumentView;

import java.util.ArrayList;
import java.util.HashMap;

public class DocumentViewViewManager extends ViewGroupManager<DocumentView> {

    private static final String REACT_CLASS = "RCTDocumentView";

    private SparseArray<DocumentView> mDocumentViews = new SparseArray<>();

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    private View.OnAttachStateChangeListener mOnAttachStateChangeListener = new View.OnAttachStateChangeListener() {
        @Override
        public void onViewAttachedToWindow(View v) {
            DocumentView documentView = (DocumentView) v;
            Log.d(getName(), "add to map: " + v.getId());
            mDocumentViews.put(v.getId(), documentView);
        }

        @Override
        public void onViewDetachedFromWindow(View v) {
            Log.d(getName(), "remove from map: " + v.getId());
            mDocumentViews.remove(v.getId());
        }
    };

    @Override
    protected DocumentView createViewInstance(ThemedReactContext reactContext) {
        DocumentView documentView = new DocumentView(reactContext);
        documentView.setup(reactContext);
        documentView.addOnAttachStateChangeListener(mOnAttachStateChangeListener);

        return documentView;
    }

    @ReactProp(name = "document")
    public void setDocument(DocumentView documentView, @NonNull String filepath) {
        documentView.setDocument(filepath);
    }

    @ReactProp(name = "password")
    public void setPassword(DocumentView documentView, @Nullable String password) {
        documentView.setPassword(password);
    }

    @ReactProp(name = "leadingNavButtonIcon")
    public void setNavButtonIcon(DocumentView documentView, @NonNull String resName) {
        documentView.setNavResName(resName);
    }

    @ReactProp(name = "showLeadingNavButton")
    public void setShowNavButton(DocumentView documentView, boolean show) {
        documentView.setShowNavIcon(show);
    }

    @ReactProp(name = "disabledElements")
    public void setDisabledElements(DocumentView documentView, @NonNull ReadableArray array) {
        documentView.setDisabledElements(array);
    }

    @ReactProp(name = "disabledTools")
    public void setDisabledTools(DocumentView documentView, @NonNull ReadableArray array) {
        documentView.setDisabledTools(array);
    }

    @ReactProp(name = "customHeaders")
    public void setCustomHeaders(DocumentView documentView, @Nullable ReadableMap map) {
        documentView.setCustomHeaders(map);
    }

    @ReactProp(name = "initialPageNumber")
    public void setInitialPageNumber(DocumentView documentView, int pageNum) {
        documentView.setInitialPageNumber(pageNum);
    }

    @ReactProp(name = "pageNumber")
    public void setPageNumber(DocumentView documentView, int pageNum) {
        documentView.setPageNumber(pageNum);
    }

    @ReactProp(name = "topToolbarEnabled")
    public void setTopToolbarEnabled(DocumentView documentView, boolean topToolbarEnabled) {
        documentView.setTopToolbarEnabled(topToolbarEnabled);
    }

    @ReactProp(name = "bottomToolbarEnabled")
    public void setBottomToolbarEnabled(DocumentView documentView, boolean bottomToolbarEnabled) {
        documentView.setBottomToolbarEnabled(bottomToolbarEnabled);
    }

    @ReactProp(name = "pageIndicatorEnabled")
    public void setPageIndicatorEnabled(DocumentView documentView, boolean pageIndicatorEnabled) {
        documentView.setPageIndicatorEnabled(pageIndicatorEnabled);
    }

    @ReactProp(name = "readOnly")
    public void setReadOnly(DocumentView documentView, boolean readOnly) {
        documentView.setReadOnly(readOnly);
    }

    @ReactProp(name = "fitMode")
    public void setFitMode(DocumentView documentView, String fitMode) {
        documentView.setFitMode(fitMode);
    }

    @ReactProp(name = "layoutMode")
    public void setLayoutMode(DocumentView documentView, String layoutMode) {
        documentView.setLayoutMode(layoutMode);
    }

    @ReactProp(name = "padStatusBar")
    public void setPadStatusBar(DocumentView documentView, boolean padStatusBar) {
        documentView.setPadStatusBar(padStatusBar);
    }

    @ReactProp(name = "continuousAnnotationEditing")
    public void setContinuousAnnotationEditing(DocumentView documentView, boolean contEditing) {
        documentView.setContinuousAnnotationEditing(contEditing);
    }

    @ReactProp(name = "annotationAuthor")
    public void setAnnotationAuthor(DocumentView documentView, String author) {
        documentView.setAnnotationAuthor(author);
    }

    @ReactProp(name = "showSavedSignatures")
    public void setShowSavedSignatures(DocumentView documentView, boolean show) {
        documentView.setShowSavedSignatures(show);
    }

    @ReactProp(name = "isBase64String")
    public void setIsBase64String(DocumentView documentView, boolean isBase64) {
        documentView.setIsBase64String(isBase64);
    }

    @ReactProp(name = "autoSaveEnabled")
    public void setAutoSaveEnabled(DocumentView documentView, boolean autoSaveEnabled) {
        documentView.setAutoSaveEnabled(autoSaveEnabled);
    }

    @ReactProp(name = "useStylusAsPen")
    public void setUseStylusAsPen(DocumentView documentView, boolean useStylusAsPen) {
        documentView.setUseStylusAsPen(useStylusAsPen);
    }

    @ReactProp(name = "collabEnabled")
    public void setCollabEnabled(DocumentView documentView, boolean collabEnabled) {
        documentView.setCollabEnabled(collabEnabled);
    }

    @ReactProp(name = "currentUser")
    public void setCurrentUser(DocumentView documentView, String currentUser) {
        documentView.setCurrentUser(currentUser);
    }

    @ReactProp(name = "currentUserName")
    public void setCurrentUserName(DocumentView documentView, String currentUserName) {
        documentView.setCurrentUserName(currentUserName);
    }

    @ReactProp(name = "annotationMenuItems")
    public void setAnnotationMenuItems(DocumentView documentView, @NonNull ReadableArray items) {
        documentView.setAnnotationMenuItems(items);
    }

    @ReactProp(name = "longPressMenuItems")
    public void setLongPressMenuItems(DocumentView documentView, @NonNull ReadableArray items) {
        documentView.setLongPressMenuItems(items);
    }

    @ReactProp(name = "longPressMenuEnabled")
    public void setLongPressMenuEnabled(DocumentView documentView, boolean longPressMenuEnabled) {
        documentView.setLongPressMenuEnabled(longPressMenuEnabled);
    }

    @ReactProp(name = "hideAnnotationMenu")
    public void setHideAnnotationMenu(DocumentView documentView, @NonNull ReadableArray tools) {
        documentView.setHideAnnotationMenu(tools);
    }

    @ReactProp(name = "pageChangeOnTap")
    public void setPageChangeOnTap(DocumentView documentView, boolean pageChangeOnTap) {
        documentView.setPageChangeOnTap(pageChangeOnTap);
    }

    @ReactProp(name = "thumbnailViewEditingEnabled")
    public void setThumbnailViewEditingEnabled(DocumentView documentView, boolean thumbnailViewEditingEnabled) {
        documentView.setThumbnailViewEditingEnabled(thumbnailViewEditingEnabled);
    }

    @ReactProp(name = "selectAnnotationAfterCreation")
    public void setSelectAnnotationAfterCreation(DocumentView documentView, boolean selectAnnotationAfterCreation) {
        documentView.setSelectAnnotationAfterCreation(selectAnnotationAfterCreation);
    }

    @ReactProp(name = "overrideAnnotationMenuBehavior")
    public void setOverrideAnnotationMenuBehavior(DocumentView documentView, @NonNull ReadableArray items) {
        documentView.setOverrideAnnotationMenuBehavior(items);
    }

    @ReactProp(name = "overrideLongPressMenuBehavior")
    public void setOverrideLongPressMenuBehavior(DocumentView documentView, @NonNull ReadableArray items) {
        documentView.setOverrideLongPressMenuBehavior(items);
    }

    @ReactProp(name = "overrideBehavior")
    public void setOverrideBehavior(DocumentView documentView, @NonNull ReadableArray items) {
        documentView.setOverrideBehavior(items);
    }

    @ReactProp(name = "followSystemDarkMode")
    public void setFollowSystemDarkMode(DocumentView documentView, boolean followSystem) {
        PdfViewCtrlSettingsManager.setFollowSystemDarkMode(documentView.getContext(), followSystem);
    }

    @ReactProp(name = "signSignatureFieldsWithStamps")
    public void setSignSignatureFieldsWithStamps(DocumentView documentView, boolean signWithStamp) {
        documentView.setSignSignatureFieldsWithStamps(signWithStamp);
    }

    public void importAnnotationCommand(int tag, String xfdfCommand, boolean initialLoad) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.importAnnotationCommand(xfdfCommand, initialLoad);
        } else {
            throw new PDFNetException("", 0L, getName(), "importAnnotationCommand", "set collabEnabled to true is required.");
        }
    }

    public void importAnnotations(int tag, String xfdf) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.importAnnotations(xfdf);
        } else {
            throw new PDFNetException("", 0L, getName(), "importAnnotations", "Unable to find DocumentView.");
        }
    }

    public String exportAnnotations(int tag, ReadableMap options) throws Exception {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            return documentView.exportAnnotations(options);
        } else {
            throw new PDFNetException("", 0L, getName(), "exportAnnotations", "Unable to find DocumentView.");
        }
    }

    public String saveDocument(int tag) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            return documentView.saveDocument();
        } else {
            throw new PDFNetException("", 0L, getName(), "saveDocument", "Unable to find DocumentView.");
        }
    }

    public void flattenAnnotations(int tag, boolean formsOnly) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.flattenAnnotations(formsOnly);
        } else {
            throw new PDFNetException("", 0L, getName(), "flattenAnnotations", "Unable to find DocumentView.");
        }
    }

    public void setToolMode(int tag, String item) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.setToolMode(item);
        } else {
            throw new PDFNetException("", 0L, getName(), "setToolMode", "Unable to find DocumentView.");
        }
    }

    public boolean commitTool(int tag) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            return documentView.commitTool();
        } else {
            throw new PDFNetException("", 0L, getName(), "commitTool", "Unable to find DocumentView.");
        }
    }

    public int getPageCount(int tag) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            return documentView.getPageCount();
        } else {
            throw new PDFNetException("", 0L, getName(), "getPageCount", "Unable to find DocumentView.");
        }
    }

    public void setFlagForFields(int tag, ReadableArray fields, Integer flag, Boolean value) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.setFlagForFields(fields, flag, value);
        } else {
            throw new PDFNetException("", 0L, getName(), "setFlagForFields", "Unable to find DocumentView.");
        }
    }

    public void setValueForFields(int tag, ReadableMap map) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.setValueForFields(map);
        } else {
            throw new PDFNetException("", 0L, getName(), "setValueForFields", "Unable to find DocumentView.");
        }
    }

    public void deleteAnnotations(int tag, ReadableArray annots) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.deleteAnnotations(annots);
        } else {
            throw new PDFNetException("", 0L, getName(), "deleteAnnotations", "Unable to find DocumentView.");
        }
    }

    public boolean handleBackButton(int tag) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            return documentView.handleBackButton();
        } else {
            throw new PDFNetException("", 0L, getName(), "handleBackButton", "Unable to find DocumentView.");
        }
    }

    @Override
    public boolean needsCustomLayoutForChildren() {
        return true;
    }

    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        for (int i = 0; i < mDocumentViews.size(); i++) {
            int key = mDocumentViews.keyAt(i);
            DocumentView documentView = mDocumentViews.get(key);
            documentView.onActivityResult(requestCode, resultCode, data);
        }
    }


    
    // CAT Europe

    public int currentPage(int tag) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            return documentView.currentPage();
        } else {
            throw new PDFNetException("", 0L, getName(), "currentPage", "Unable to find DocumentView.");
        }
    }


    public ReadableMap getDimensions(int tag) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            return documentView.getDimensions();
        } else {
            throw new PDFNetException("", 0L, getName(), "getDimensions", "Unable to find DocumentView.");
        }
    }


    public void jumpTo(int tag, int page_num) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.jumpTo(page_num);
        } else {
            throw new PDFNetException("", 0L, getName(), "jumpTo", "Unable to find DocumentView.");
        }
    }


    public void rotate(int tag, boolean ccw) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.rotate(ccw);
        } else {
            throw new PDFNetException("", 0L, getName(), "rotate", "Unable to find DocumentView.");
        }
    }

    public void toggleSlider(int tag, boolean toggle) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.toggleSlider(toggle);
        } else {
            throw new PDFNetException("", 0L, getName(), "toggleSlider", "Unable to find DocumentView.");
        }
    }



    public ReadableArray search(int tag, String searchString, boolean isCase, boolean isWhole) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            return documentView.search(searchString, isCase, isWhole);
        } else {
            throw new PDFNetException("", 0L, getName(), "search", "Unable to find DocumentView.");
        }
    }


    public ReadableArray getOutline(int tag) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            return documentView.getOutline();
        } else {
            throw new PDFNetException("", 0L, getName(), "getOutline", "Unable to find DocumentView.");
        }
    }


    public void getThumbnail(int tag, int page, Promise promise) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.getThumbnail(page, promise);
        } else {
            throw new PDFNetException("", 0L, getName(), "getThumbnail", "Unable to find DocumentView.");
        }
    }


    public void abortGetThumbnail(int tag) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.abortGetThumbnail();
        } else {
            throw new PDFNetException("", 0L, getName(), "abortGetThumb", "Unable to find DocumentView.");
        }
    }



    public void findText(int tag, String serachString) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.findText(serachString);
        } else {
            throw new PDFNetException("", 0L, getName(), "findText", "Unable to find DocumentView.");
        }
    }


    public void cancelFindText(int tag) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.cancelFindText();
        } else {
            throw new PDFNetException("", 0L, getName(), "CancelfindText", "Unable to find DocumentView.");
        }
    }

    public void findTextResult(int tag, boolean nextprev) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.findTextResult(nextprev);
        } else {
            throw new PDFNetException("", 0L, getName(), "FindTextResult", "Unable to find DocumentView.");
        }
    }


    public void appendSchoolLogo(int tag, String base64str, boolean isDuplex) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.appendSchoolLogo(base64str, isDuplex);
        } else {
            throw new PDFNetException("", 0L, getName(), "AppendSchoolLogo", "Unable to find DocumentView.");
        }
    }


    public void changeBackground(int tag, int r, int g, int b) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.changeBackground(r, g, b);
        } else {
            throw new PDFNetException("", 0L, getName(), "changeBackground", "Unable to find DocumentView.");
        }
    }


    public void setContinuous(int tag, boolean toggle) throws PDFNetException {
        DocumentView documentView = mDocumentViews.get(tag);
        if (documentView != null) {
            documentView.setContinuous(toggle);
        } else {
            throw new PDFNetException("", 0L, getName(), "changeBackground", "Unable to find DocumentView.");
        }
    }


}
