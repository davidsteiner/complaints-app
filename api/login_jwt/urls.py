from django.conf.urls import url

import login_jwt.views as views


urlpatterns = [
    url(r'^register/', views.Register.as_view()),
]
