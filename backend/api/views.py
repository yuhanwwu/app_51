from django.shortcuts import render

# Create your views here.
from rest_framework import viewsets
from .models import User, RepeatTask, OneOffTask
from .serializers import UserSerializer, RepeatTaskSerializer, OneOffTaskSerializer

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json

def test_view(request):
    return JsonResponse({"message": "Test OK"})
# class NoteViewSet(viewsets.ModelViewSet):
#     queryset = Note.objects.all()
#     serializer_class = NoteSerializer

# class FlatViewSet(viewsets.ModelViewSet):
#     queryset = Flat.objects.all()
#     serializer_class = FlatSerializer
@csrf_exempt  # disable CSRF for testing — secure this later!
def custom_login(request):
    if request.method == "POST":
        data = json.loads(request.body)
        username = data.get("username")

        try:
            user = User.objects.get(username=username)
            return JsonResponse({
                "success": True,
                "username": user.username,
                "name": user.name
            })
        except User.DoesNotExist:
            return JsonResponse({"success": False, "error": "User not found"}, status=404)

    return JsonResponse({"error": "Invalid method"}, status=405)

def all_users(request):
    if request.method == "GET":
        users = User.objects.all().values("username", "name")
        users_list = list(users)
        return JsonResponse(users_list, safe=False)
    return JsonResponse({"error": "Method not allowed"}, status=405)

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

class RepeatTaskViewSet(viewsets.ModelViewSet):
    queryset = RepeatTask.objects.all()
    serializer_class = RepeatTaskSerializer

class OneOffTaskViewSet(viewsets.ModelViewSet):
    queryset = OneOffTask.objects.all()
    serializer_class = OneOffTaskSerializer