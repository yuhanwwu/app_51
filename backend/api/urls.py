from django.urls import path, include
from django.contrib import admin
from rest_framework.routers import DefaultRouter
from .views import UserViewSet, RepeatTaskViewSet, OneOffTaskViewSet

router = DefaultRouter()
# router.register(r'notes', NoteViewSet)
# router.register(r'flats', FlatViewSet)
router.register(r'users', UserViewSet)
router.register(r'repeat-tasks', RepeatTaskViewSet)
router.register(r'one-off-tasks', OneOffTaskViewSet)

urlpatterns = [
    path('api/', include(router.urls)),
    path('admin/', admin.site.urls)
] 