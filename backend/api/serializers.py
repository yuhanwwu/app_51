from rest_framework import serializers
# from .models import Note
from .models import User, RepeatTask, OneOffTask

# class NoteSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = Note
#         fields = '__all__'

# class FlatSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = Flat
#         fields = '__all__'


class RepeatTaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = RepeatTask
        fields = '__all__'
    def validate_frequency(self, value):
        if value <= 0 :
            raise serializers.ValidationError("Frequency must be greater than 0.")
        return value

class OneOffTaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = OneOffTask
        fields = '__all__'

class UserSerializer(serializers.ModelSerializer):
    assigned_repeat_tasks = RepeatTaskSerializer(many=True, read_only=True, source='repeat_tasks_assigned')
    assigned_oneoff_tasks = OneOffTaskSerializer(many=True, read_only=True, source='one_off_tasks_assigned')
    class Meta:
        model = User
        fields = ['username', 'name', 'assigned_repeat_tasks', 'assigned_oneoff_tasks']
    def validate_username(self, value):
        user_qs = User.objects.filter(username=value)
        if self.instance:
            user_qs = user_qs.exclude(pk=self.instance.pk)
        if user_qs.exists():
            raise serializers.ValidationError("This username is already taken.")
        return value
    def validate_name(self, value):
        user_qs = User.objects.filter(name=value)
        if self.instance:
            user_qs = user_qs.exclude(pk=self.instance.pk)
        if user_qs.exists():
            raise serializers.ValidationError("This name is already taken.")
        return value