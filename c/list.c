#include "list.h"
#include "parser.h"
#include <stdbool.h>
#include <stdlib.h>

List* List_Create()
{
    List* list = (List*)calloc(1, sizeof(struct list));

    list->head.next = &list->tail;
    list->tail.prev = &list->head;

    return list;
}

List* List_Clone(List* l)
{
    List* newList = List_Create();
    forall (elem, l) {
        List_Append(newList, elem->data);
    }
    return newList;
}

struct listElem* List_Begin(struct list* list)
{
    return list->head.next;
}

struct listElem* List_Next(struct listElem* elem)
{
    return elem->next;
}

struct listElem* List_End(struct list* list)
{
    return &list->tail;
}

void List_Append(List* list, void* data)
{
    ListElem* elem = (ListElem*)malloc(sizeof(struct listElem));
    elem->data = data;
    elem->prev = list->tail.prev;
    elem->next = &list->tail;
    list->tail.prev->next = elem;
    list->tail.prev = elem;
    list->size++;
}

bool List_Contains(List* list, void* needle, bool(*compare)(void*, void*)) 
{
    forall(elem, list) 
    {
        if (compare(elem->data, needle)) 
        {
            return true;
        }
    }
    return false;
}

void* List_Get(List* list, int i)
{
    ListElem* elem = list->head.next;
    for (; i > 0 && elem != &list->tail; i--, elem = elem->next)
        ;
    return elem->data;
}