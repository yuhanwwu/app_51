# from django.shortcuts import render

# # Create your views here.
# from rest_framework import viewsets
# from .models import User, RepeatTask, OneOffTask
# from .serializers import UserSerializer, RepeatTaskSerializer, OneOffTaskSerializer


# # class NoteViewSet(viewsets.ModelViewSet):
# #     queryset = Note.objects.all()
# #     serializer_class = NoteSerializer

# # class FlatViewSet(viewsets.ModelViewSet):
# #     queryset = Flat.objects.all()
# #     serializer_class = FlatSerializer

# class UserViewSet(viewsets.ModelViewSet):
#     queryset = User.objects.all()
#     serializer_class = UserSerializer

# class RepeatTaskViewSet(viewsets.ModelViewSet):
#     queryset = RepeatTask.objects.all()
#     serializer_class = RepeatTaskSerializer

# class OneOffTaskViewSet(viewsets.ModelViewSet):
#     queryset = OneOffTask.objects.all()
#     serializer_class = OneOffTaskSerializer

from django.http import JsonResponse, HttpResponseBadRequest, HttpResponseNotAllowed
from django.views.decorators.csrf import csrf_exempt
from .jsondb import *

import json

@csrf_exempt
def users_view(request):
    if request.method == 'GET':
        return JsonResponse(get_users(), safe=False)
    elif request.method == 'POST':
        user = json.loads(request.body)
        return JsonResponse(add_user(user), status=201)
    return HttpResponseNotAllowed(['GET', 'POST'])

@csrf_exempt
def repeat_tasks_view(request):
    if request.method == 'GET':
        return JsonResponse(get_repeat_tasks(), safe=False)
    elif request.method == 'POST':
        task = json.loads(request.body)
        return JsonResponse(add_repeat_task(task), status=201)
    return HttpResponseNotAllowed(['GET', 'POST'])

@csrf_exempt
def one_off_tasks_view(request):
    if request.method == 'GET':
        return JsonResponse(get_one_off_tasks(), safe=False)
    elif request.method == 'POST':
        task = json.loads(request.body)
        return JsonResponse(add_one_off_task(task), status=201)
    return HttpResponseNotAllowed(['GET', 'POST'])

@csrf_exempt
def mark_repeat_done_view(request, task_id):
    if request.method != 'POST':
        return HttpResponseNotAllowed(['POST'])
    try:
        data = json.loads(request.body)
        mark_repeat_task_done(task_id, data["user_id"])
        return JsonResponse({ "status": "done" })
    except Exception as e:
        return HttpResponseBadRequest(f"Error: {str(e)}")
