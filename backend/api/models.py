from django.db import models

# Create your models here.

from django.db import models

# class Note(models.Model):
#     title = models.CharField(max_length=100)
#     content = models.TextField()
#     created_at = models.DateTimeField(auto_now_add=True)

#     def __str__(self):
#         return self.title

    
class Flat(models.Model):
    size = models.IntegerField()
    flatname = models.CharField(max_length = 30)
    def __str__(self): 
        return self.flatname
    class Meta:
        verbose_name = "Flat"
        verbose_name_plural = "Flats"
    
class User(models.Model):
    username = models.CharField(max_length = 20, unique=True)
    flat = models.ForeignKey(Flat,on_delete=models.CASCADE)
    name = models.CharField(max_length = 30)
    def __str__(self):
        return self.name
    class Meta:
        verbose_name = "Flatmate"
        verbose_name_plural = "Flatmates"

class RepeatTask(models.Model):
    description = models.CharField(max_length=100)
    flat = models.ForeignKey(Flat,on_delete=models.CASCADE)
    assignedto = models.ForeignKey(User, null=True, on_delete=models.SET_NULL, related_name="repeat_tasks_assigned") #flatmate designated to do it
    frequency = models.IntegerField() #how many days between task being done
    lastdoneon = models.DateTimeField(null=True) #date it was last done
    lastdoneby = models.ForeignKey(User, null=True, on_delete=models.SET_NULL) #who did it last
    def __str__(self):
        return self.description
    class Meta:
        verbose_name = "Repeat Task"
        verbose_name_plural = "Repeat Tasks"

class OneOffTask(models.Model):
    description = models.CharField(max_length=100)
    flat = models.ForeignKey(Flat,on_delete=models.CASCADE)
    assignedto = models.ForeignKey(User, null=True, on_delete=models.SET_NULL, related_name="one_off_tasks_assigned") #who it is designated to
    setdate = models.DateTimeField(auto_now_add=True) #when task was created
    priority = models.BooleanField() #if its urgent
    def __str__(self):
        return self.description
    class Meta:
        verbose_name = "One Off Task"
        verbose_name_plural = "One Off Tasks"

#TODO add ordering on tasks (time left to next completion, reverse of date created (high priority first))