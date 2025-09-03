/// Firestore content values helper
library;

export 'package:cv/cv.dart';
export 'package:tekartik_firebase_firestore/firestore.dart';

export 'src/v2/builder.dart' show cvFirestoreAddBuilder;
export 'src/v2/cv_collection_reference.dart'
    show
        CvCollectionReference,
        CollectionReferenceCvExtension,
        CvCollectionReferenceExtension;
export 'src/v2/cv_document.dart'
    show
        CvFirestoreDocument,
        CvFirestoreDocumentCloneExt,
        CvFirestoreDocumentBase,
        CvFirestoreMapDocument,
        CvFirestoreDocumentExt;
export 'src/v2/cv_document_reference.dart'
    show
        CvDocumentReference,
        DocumentReferenceCvExtension,
        CvDocumentReferenceExtension,
        cvRootDocumentReference;
export 'src/v2/cv_query_reference.dart' show CvQueryReference;
export 'src/v2/cv_utils.dart' show TekartikCvFirestoreCvDocumentListCvExt;
export 'src/v2/fill_options.dart' show cvFirestoreFillOptions1;
export 'src/v2/firestore_extension.dart'
    show
        CvFirestoreDocumentIterableExt,
        CvFirestoreDocumentSnapshotExt,
        CvFirestoreDocumentSnapshotsExt,
        CvFirestoreQuerySnapshotExt,
        CvFirestoreExt,
        CvFirestoreCollectionReferenceExt,
        CvFirestoreDocumentReferenceExt,
        CvFirestoreQueryExt,
        CvFirestoreWriteBatch,
        CvFirestoreTransaction;
export 'src/v2/json_utils.dart'
    show
        infoJsonListToDocumentList,
        infoJsonToDocument,
        TekartikCvFirestoreDocumentSnapshotListInfoJsonListExt,
        TekartikCvFirestoreCvDocumentInfoJsonExt,
        TekartikCvFirestoreCvDocumentListInfoJsonListExt;

export 'src/v2/map_extension.dart'
    show AppCvFirestoreFieldMapExt, WithServerTimestampMixin;
export 'src/v2/query_utils.dart' show CvQueryReferenceUtilsExt;
