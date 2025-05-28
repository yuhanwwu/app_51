from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import FlatViewSet, UserViewSet, RepeatTaskViewSet, OneOffTaskViewSet

router = DefaultRouter()
# router.register(r'notes', NoteViewSet)
router.register(r'flats', FlatViewSet)
router.register(r'users', UserViewSet)
router.register(r'repeat-tasks', RepeatTaskViewSet)
router.register(r'one-off-tasks', OneOffTaskViewSet)

urlpatterns = [
    path('api/', include(router.urls)),
] 