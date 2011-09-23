#ifndef CV_PRE_STRUCT_H_
#define CV_PRE_STRUCT_H_

#include<opencv2/core/core_c.h>

typedef struct DummyNodeType {
				void* dummy;
}DummyNodeType;

typedef struct CvTreeNode {
	CV_TREE_NODE_FIELDS(DummyNodeType);
}CvTreeNode;

#endif
