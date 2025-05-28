from django.shortcuts import render

# Create your views here.
from rest_framework import viewsets
from .models import Flat, User, RepeatTask, OneOffTask
from .serializers import FlatSerializer, UserSerializer, RepeatTaskSerializer, OneOffTaskSerializer


# class NoteViewSet(viewsets.ModelViewSet):
#     queryset = Note.objects.all()
#     serializer_class = NoteSerializer

class FlatViewSet(viewsets.ModelViewSet):
    queryset = Flat.objects.all()
    serializer_class = FlatSerializer

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

class RepeatTaskViewSet(viewsets.ModelViewSet):
    queryset = RepeatTask.objects.all()
    serializer_class = RepeatTaskSerializer

class OneOffTaskViewSet(viewsets.ModelViewSet):
    queryset = OneOffTask.objects.all()
    serializer_class = OneOffTaskSerializer