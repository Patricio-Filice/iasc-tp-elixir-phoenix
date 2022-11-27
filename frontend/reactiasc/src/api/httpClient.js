import { ControlCameraOutlined } from '@material-ui/icons';
import axios from 'axios';
import Swal from 'sweetalert2'
const clientCount = (+process.env.REACT_APP_API_BACKEND_TO_PORT - +process.env.REACT_APP_API_BACKEND_FROM_PORT)+1;
 
/*export const  = axios.create({
  baseURL: process.env.REACT_APP_API_BACKEND_URL+":"+ process.env.REACT_APP_API_BACKEND_FRONT_PORT,
  withCredentials: true,
  timeout: 20000
});*/

const httpClients = Array.from(Array((+process.env.REACT_APP_API_BACKEND_TO_PORT - +process.env.REACT_APP_API_BACKEND_FROM_PORT)+1).keys()).map(key => {
  return axios.create({
    baseURL: process.env.REACT_APP_API_BACKEND_URL+":"+( parseInt(process.env.REACT_APP_API_BACKEND_FROM_PORT) + key),
    withCredentials: true,
    timeout: 500
  })
})
export const httpClientWrapper = {

  async get(url){
    let response = null;
    let index = 0;
    while(response || index <clientCount){
      const client =  httpClients[index];
      try{
        const res = await client.get(url);
        if(res.request.status < 500){
          return res;
        }
      }
      catch(er){
        
      }
      finally{
        index +=1;
      }
    }
  },

  async post(url, param){
    let response = null;
    let index = 0;
    while(response || index <clientCount){
      const client =  httpClients[index];
      try{
        const res = await client.post(url, param);
        if(res.request.status < 500){
          return res;
        }
      }
      catch(er){
        
      }
      finally{
        index +=1;
      }
    }
  },
  async delete(url){
    let response = null;
    let index = 0;
    while(response || index <clientCount){
      const client =  httpClients[index];
      try{
        const res = await client.delete(url);
        if(res.request.status < 500){
          return res;
        }
      }
      catch(er){
        
      }
      finally{
        index +=1;
      }
    }
  },
  async put(url, param){
    let response = null;
    let index = 0;
    while(response || index <clientCount){
      const client =  httpClients[index];
      try{
        const res = await client.put(url, param);
        if(res.request.status < 500){
          return res;
        }
      }
      catch(er){
        
      }
      finally{
        index +=1;
      }
    }
  }
} 
    
 
const expiredSessionModalBuilder = signoutCb => {
  return Swal.fire({
    title: "Session Expired",
    text: "Your session has expired. You will be redirected to the sign in page",
    type: "warning",
    showCancelButton: false,
    confirmButtonColor: "#DD6B55",
    confirmButtonText: "Yes",
    closeOnConfirm: false
  }).then(() => { 
    signoutCb()
  });
}

export const initializeInterceptors = (signout) => {
 /* httpClient.interceptors.response.use(function (response) {
    // Any status code that lie within the range of 2xx cause this function to trigger
    // Do something with response data
    return response;
  }, function (error) {
    if (error?.response?.status === 401 && error?.response?.config?.url !== '/login') {
      // signout and redirect to login
      expiredSessionModalBuilder(() => signout())
    }
    // Any status codes that falls outside the range of 2xx cause this function to trigger
    // Do something with response error
    return Promise.reject(error);
  });*/
}
    
  