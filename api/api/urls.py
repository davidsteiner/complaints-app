from complaints.views import ComplaintView, AllComplaintsView
from django.conf.urls import url, include
from django.contrib import admin
from rest_framework_jwt.views import obtain_jwt_token

import login_jwt.urls


urlpatterns = [
    url(r'^api/api-token-auth/', obtain_jwt_token),
    url(r'^admin/', admin.site.urls),
    url(r'^api/', include(login_jwt.urls)),
    url(r'api/new-complaint/', ComplaintView.as_view()),
    url(r'api/complaints/', AllComplaintsView.as_view())
]
