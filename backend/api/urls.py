# from django.urls import path, include
# from django.contrib import admin
# from rest_framework.routers import DefaultRouter
# from .views import UserViewSet, RepeatTaskViewSet, OneOffTaskViewSet, custom_login, all_users, test_view

# router = DefaultRouter()
# # router.register(r'notes', NoteViewSet)
# # router.register(r'flats', FlatViewSet)
# router.register(r'users', UserViewSet)
# router.register(r'repeat-tasks', RepeatTaskViewSet)
# router.register(r'one-off-tasks', OneOffTaskViewSet)

# urlpatterns = [
#     # path('api/', include(router.urls)),
#     # path('admin/', admin.site.urls),
#     path('', include(router.urls)),
#     path('login/', custom_login, name='custom_login'),
#     path('users/', all_users, name='all_users'),
#     path('test/', test_view, name='test_view'),

# ] 

from django.urls import path
from . import views

urlpatterns = [
    path('api/users/', views.users_view),
    path('api/repeat-tasks/', views.repeat_tasks_view),
    path('api/one-off-tasks/', views.one_off_tasks_view),
    path('api/repeat-tasks/<int:task_id>/done/', views.mark_repeat_done_view),
]
