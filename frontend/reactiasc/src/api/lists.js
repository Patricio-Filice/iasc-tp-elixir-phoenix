import {  httpClientWrapper } from "./httpClient"

export const getAllLists= async () => {
    const res = await httpClientWrapper.get('/lists')
    return res.data;
}

export const createList = async (list) => {
    const res = await httpClientWrapper.post('/lists/',{name:list.name})
    return res.data;
}