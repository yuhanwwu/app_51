from rest_framework import serializers
# from .models import Note
from .models import Flat, User, RepeatTask, OneOffTask

# class NoteSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = Note
#         fields = '__all__'

class FlatSerializer(serializers.ModelSerializer):
    class Meta:
        model = Flat
        fields = '__all__'


class RepeatTaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = RepeatTask
        fields = '__all__'


class OneOffTaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = OneOffTask
        fields = '__all__'

class UserSerializer(serializers.ModelSerializer):
    assigned_repeat_tasks = RepeatTaskSerializer(many=True, read_only=True, source='repeat_tasks_assigned')
    assigned_oneoff_tasks = OneOffTaskSerializer(many=True, read_only=True, source='one_off_tasks_assigned')
    class Meta:
        model = User
        fields = ['username', 'name', 'flat', 'assigned_repeat_tasks', 'assigned_oneoff_tasks']