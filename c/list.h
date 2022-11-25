// � 2021-2022 Joseph Shimel. All rights reserved.

#ifndef List_H
#define List_H

#include <stdbool.h>

#define forall(e, l) for (ListElem* e = List_Begin(l); e != List_End(l); e = e->next)

// Doubly linked list node
typedef struct listElem {
    struct listElem* next;
    struct listElem* prev;
    void* data;
} ListElem;

// Doubly linked list, with head and tail
typedef struct list {
    struct listElem head;
    struct listElem tail;
    int size;
} List;

List* List_Create();
List* List_Clone(List*);
struct listElem* List_Begin(struct list*);
struct listElem* List_Next(struct listElem*);
struct listElem* List_End(struct list*);
void List_Append(List* list, void*);
bool List_Contains(List* list, void*, bool(*compare)(void*, void*));
void* List_Get(List* list, int i);

#endif