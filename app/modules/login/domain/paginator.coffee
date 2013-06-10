_ = require './myunderscore'

module.exports =
    paging: (query) ->
        page = query.page || 1
        limit = query.limit || 5
        skip = (page-1) * 5
        return {
            page: page
            limit: limit
            skip: skip
        }

    pageCountCalc: (list, pageSize) ->
        pageCount = parseInt(list.length / pageSize)
        itemCount = list.length
        fractionalPages = 0
        if list.length % pageSize > 0
            fractionalPages = 1
        pageCount += fractionalPages
        return {
           pageCount: pageCount
           itemCount: itemCount 
        }

    diffFilter: (masterList, compareList, comparisonProperty, paging) ->
        comparisonProperties = _.pluck masterList, comparisonProperty
        filteredList = _.difference comparisonProperties, compareList
        filteredList = _.skipTake filteredList, paging
        filteredList = _.filter masterList, (masterItem) ->
            return _.contains filteredList, masterItem[comparisonProperty]
        result = @createPagedResult filteredList, paging
        return result

    createPagedResult: (list, paging) ->
        pageInfo = @pageCountCalc list, paging.limit
        result = 
            items: list
            pageCount: pageInfo.pageCount
            itemCount: pageInfo.itemCount
        return result
