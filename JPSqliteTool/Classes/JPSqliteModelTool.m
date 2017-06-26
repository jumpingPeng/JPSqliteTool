//
//  ViewController.h
//  JPSqliteTool
//
//  Created by JUMPING on 2016/12/27.
//  Copyright © 2017年 JUMPING. All rights reserved.
//

#import "JPSqliteModelTool.h"
#import "JPModelTool.h"
#import "JPSqliteTool.h"
#import "JPTableTool.h"


@implementation JPSqliteModelTool
/**
 根据一个模型类, 创建数据库表
 // 关于这个工具类的封装
 // 实现方案 2
 // 1. 基于配置
 // 2. runtime动态获取
 @param cls 类名
 @param uid 用户唯一标识
 @return 是否创建成功
 */
+ (BOOL)createTable:(Class)cls uid:(NSString *)uid {
    
    // 1. 创建表格的sql语句给拼接出来
    // 尽可能多的, 能够自己获取, 就自己获取, 实在判定不了用的意图的, 只能让用户来告诉我们
    
    // create table if not exists 表名(字段1 字段1类型, 字段2 字段2类型 (约束),...., primary key(字段))
    // 1.1 获取表格名称
    NSString *tableName = [JPModelTool tableName:cls];
    
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSLog(@"如果想要操作这个模型, 必须要实现+ (NSString *)primaryKey;这个方法, 来告诉我主键信息");
        return NO;
    }
    
    NSString *primaryKey = [cls primaryKey];
    
    // 1.2 获取一个模型里面所有的字段, 以及类型
    NSString *createTableSql = [NSString stringWithFormat:@"create table if not exists %@(%@, primary key(%@))", tableName, [JPModelTool columnNamesAndTypesStr:cls], primaryKey];
    
    
    // 2. 执行
    return [JPSqliteTool deal:createTableSql uid:uid];

}


/**
 判断一个表格是否需要更新

 @param cls 类名
 @param uid 用户唯一标识
 @return 是否需要更新
 */
+ (BOOL)isTableRequiredUpdate:(Class)cls uid:(NSString *)uid {
    // 1. 获取类对应的所有有效成员变量名称, 并排序
    NSArray *modelNames = [JPModelTool allTableSortedIvarNames:cls];

    // 2. 获取当前表格, 所有字段名称, 并排序
    NSArray *tableNames = [JPTableTool tableSortedColumnNames:cls uid:uid];

    // 3. 通过对比数据判定是否需要更新
    return ![modelNames isEqualToArray:tableNames];
}

/**
 更新表格

 @param cls 类名
 @param uid 用户唯一标识
 @return 是否更新成功
 */
+ (BOOL)updateTable:(Class)cls uid:(NSString *)uid {
    
    
    // 1. 创建一个拥有正确结构的临时表
    // 1.1 获取表格名称
    NSString *tmpTableName = [JPModelTool tmpTableName:cls];
    NSString *tableName = [JPModelTool tableName:cls];
    
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSLog(@"如果想要操作这个模型, 必须要实现+ (NSString *)primaryKey;这个方法, 来告诉我主键信息");
        return NO;
    }
    NSMutableArray *execSqls = [NSMutableArray array];
    NSString *primaryKey = [cls primaryKey];
    NSString *dropTmpTableSql = [NSString stringWithFormat:@"drop table if exists %@;", tmpTableName];
    [execSqls addObject:dropTmpTableSql];
    NSString *createTableSql = [NSString stringWithFormat:@"create table if not exists %@(%@, primary key(%@));", tmpTableName, [JPModelTool columnNamesAndTypesStr:cls], primaryKey];
    [execSqls addObject:createTableSql];
    // 2. 根据主键, 插入数据
    // insert into JPstu_tmp(stuNum) select stuNum from JPstu;
    NSString *insertPrimaryKeyData = [NSString stringWithFormat:@"insert into %@(%@) select %@ from %@;", tmpTableName, primaryKey, primaryKey, tableName];
    [execSqls addObject:insertPrimaryKeyData];
    // 3. 根据主键, 把所有的数据更新到新表里面
    NSArray *oldNames = [JPTableTool tableSortedColumnNames:cls uid:uid];
    NSArray *newNames = [JPModelTool allTableSortedIvarNames:cls];
    
    // 4. 获取更名字典
    NSDictionary *newNameToOldNameDic = @{};
    //  @{@"age": @"age2"};
    if ([cls respondsToSelector:@selector(newNameToOldNameDic)]) {
        newNameToOldNameDic = [cls newNameToOldNameDic];
    }
    
    for (NSString *columnName in newNames) {
        NSString *oldName = columnName;
        // 找映射的旧的字段名称
        if ([newNameToOldNameDic[columnName] length] != 0) {
            oldName = newNameToOldNameDic[columnName];
        }
        // 如果老表包含了新的列明, 应该从老表更新到临时表格里面
        if ((![oldNames containsObject:columnName] && ![oldNames containsObject:oldName]) || [columnName isEqualToString:primaryKey]) {
            continue;
        }
        //        JPstu_tmp  age
        // update 临时表 set 新字段名称 = (select 旧字段名 from 旧表 where 临时表.主键 = 旧表.主键)
        NSString *updateSql = [NSString stringWithFormat:@"update %@ set %@ = (select %@ from %@ where %@.%@ = %@.%@);", tmpTableName, columnName, oldName, tableName, tmpTableName, primaryKey, tableName, primaryKey];
        [execSqls addObject:updateSql];
    }
    
    NSString *deleteOldTable = [NSString stringWithFormat:@"drop table if exists %@;", tableName];
    [execSqls addObject:deleteOldTable];
    
    NSString *renameTableName = [NSString stringWithFormat:@"alter table %@ rename to %@;", tmpTableName, tableName];
    [execSqls addObject:renameTableName];
   
    
    return [JPSqliteTool dealSqls:execSqls uid:uid];

}


+ (BOOL)saveOrUpdateModel:(id)model uid:(NSString *)uid {
    
    // 如果用户再使用过程中, 直接调用这个方法, 去保存模型
    // 保存一个模型
    Class cls = [model class];
    // 1. 判断表格是否存在, 不存在, 则创建
    if (![JPTableTool isTableExists:cls uid:uid]) {
        [self createTable:cls uid:uid];
    }
    // 2. 检测表格是否需要更新, 需要, 更新
    if ([self isTableRequiredUpdate:cls uid:uid]) {
       BOOL updateSuccess = [self updateTable:cls uid:uid];
        if (!updateSuccess) {
            NSLog(@"更新数据库表结构失败");
            return NO;
        }
    }
    
    // 3. 判断记录是否存在, 主键
    // 从表格里面, 按照主键, 进行查询该记录, 如果能够查询到
    NSString *tableName = [JPModelTool tableName:cls];
    
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSLog(@"如果想要操作这个模型, 必须要实现+ (NSString *)primaryKey;这个方法, 来告诉我主键信息");
        return NO;
    }
    NSString *primaryKey = [cls primaryKey];
    id primaryValue = [model valueForKeyPath:primaryKey];
    
    NSString *checkSql = [NSString stringWithFormat:@"select * from %@ where %@ = '%@'", tableName, primaryKey, primaryValue];
    NSArray *result = [JPSqliteTool querySql:checkSql uid:uid];
    
    
    // 获取字段名称数组
    NSArray *columnNames = [JPModelTool classIvarNameTypeDic:cls].allKeys;
    
    // 获取值数组
    // model keyPath:
    NSMutableArray *values = [NSMutableArray array];
    for (NSString *columnName in columnNames) {
        id value = [model valueForKeyPath:columnName];
        
        if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
            // 在这里, 把字典或者数组, 处理成为一个字符串, 保存到数据库里面去
            
            // 字典/数组 -> data
            NSData *data = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:nil];
            
            // data -> nsstring
            value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        
        [values addObject:value];
    }
    
    NSInteger count = columnNames.count;
    NSMutableArray *setValueArray = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        NSString *name = columnNames[i];
        id value = values[i];
        NSString *setStr = [NSString stringWithFormat:@"%@='%@'", name, value];
        [setValueArray addObject:setStr];
    }
    
    // 更新
    // 字段名称, 字段值
    // update 表名 set 字段1=字段1值,字段2=字段2的值... where 主键 = '主键值'
    NSString *execSql = @"";
    if (result.count > 0) {
        execSql = [NSString stringWithFormat:@"update %@ set %@  where %@ = '%@'", tableName, [setValueArray componentsJoinedByString:@","], primaryKey, primaryValue];
        
        
    }else {
        // insert into 表名(字段1, 字段2, 字段3) values ('值1', '值2', '值3')
        // '   值1', '值2', '值3   '
        // 插入
        // text sz 'sz' 2 '2'
        execSql = [NSString stringWithFormat:@"insert into %@(%@) values('%@')", tableName, [columnNames componentsJoinedByString:@","], [values componentsJoinedByString:@"','"]];
    }
    
    
    return [JPSqliteTool deal:execSql uid:uid];
}


+ (BOOL)deleteModel:(id)model uid:(NSString *)uid {
    
    Class cls = [model class];
    NSString *tableName = [JPModelTool tableName:cls];
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSLog(@"如果想要操作这个模型, 必须要实现+ (NSString *)primaryKey;这个方法, 来告诉我主键信息");
        return NO;
    }
    NSString *primaryKey = [cls primaryKey];
    id primaryValue = [model valueForKeyPath:primaryKey];
    NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where %@ = '%@'", tableName, primaryKey, primaryValue];
    
    return [JPSqliteTool deal:deleteSql uid:uid];
    
}


+ (BOOL)deleteModel:(Class)cls whereStr:(NSString *)whereStr uid:(NSString *)uid {
    
    NSString *tableName = [JPModelTool tableName:cls];
    
    NSString *deleteSql = [NSString stringWithFormat:@"delete from %@", tableName];
    if (whereStr.length > 0) {
        deleteSql = [deleteSql stringByAppendingFormat:@" where %@", whereStr];
    }
    
    return [JPSqliteTool deal:deleteSql uid:uid];
    
}



+ (BOOL)deleteModel:(Class)cls columnName:(NSString *)name relation:(ColumnNameToValueRelationType)relation value:(id)value uid:(NSString *)uid {
    
    NSString *tableName = [JPModelTool tableName:cls];
    
   
    
    NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where %@ %@ '%@'", tableName, name, self.ColumnNameToValueRelationTypeDic[@(relation)], value];
    
    // 假设肯定传
    
    return [JPSqliteTool deal:deleteSql uid:uid];
}

+ (NSArray *)queryAllModels:(Class)cls uid:(NSString *)uid {
    
    NSString *tableName = [JPModelTool tableName:cls];
    // 1. sql
    NSString *sql = [NSString stringWithFormat:@"select * from %@", tableName];
    
    // 2. 执行查询,
    // key value
    // 模型的属性名称, 和属性值
    // xx 字符串
    // oo 字符串
    NSArray <NSDictionary *>*results = [JPSqliteTool querySql:sql uid:uid];
    
    
    // 3. 处理查询的结果集 -> 模型数组
    return [self parseResults:results withClass:cls];;
    
}

+ (NSArray *)queryModels:(Class)cls columnName:(NSString *)name relation:(ColumnNameToValueRelationType)relation value:(id)value uid:(NSString *)uid {
    
    NSString *tableName = [JPModelTool tableName:cls];
    // 1. 拼接sql语句
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where %@ %@ '%@' ", tableName, name, self.ColumnNameToValueRelationTypeDic[@(relation)], value];
    
    
    // 2. 查询结果集
     NSArray <NSDictionary *>*results = [JPSqliteTool querySql:sql uid:uid];
    
    return [self parseResults:results withClass:cls];
}

+ (NSArray *)queryModels:(Class)cls WithSql:(NSString *)sql uid:(NSString *)uid {
    
    // 2. 查询结果集
    NSArray <NSDictionary *>*results = [JPSqliteTool querySql:sql uid:uid];
    
    return [self parseResults:results withClass:cls];
    
}


+ (NSArray *)parseResults:(NSArray <NSDictionary *>*)results withClass:(Class)cls {

    // 3. 处理查询的结果集 -> 模型数组
    NSMutableArray *models = [NSMutableArray array];
    
    // 属性名称 -> 类型 dic
    NSDictionary *nameTypeDic = [JPModelTool classIvarNameTypeDic:cls];
    
    for (NSDictionary *modelDic in results) {
        id model = [[cls alloc] init];
        [models addObject:model];
        
        [modelDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            
            // xx NSMutableArray
            // oo NSDictionary
//            [
//            "2",
//            "3"
//            ]
            NSString *type = nameTypeDic[key];
//            NSArray
//            NSMutableArray
//            NSDictionary
//            NSMutableDictionary
            id resultValue = obj;
            if ([type isEqualToString:@"NSArray"] || [type isEqualToString:@"NSDictionary"]) {
                
                // 字符串 ->
                NSData *data = [obj dataUsingEncoding:NSUTF8StringEncoding];
                resultValue = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                
            }else if ([type isEqualToString:@"NSMutableArray"] || [type isEqualToString:@"NSMutableDictionary"]) {
                NSData *data = [obj dataUsingEncoding:NSUTF8StringEncoding];
                resultValue = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            }
            
            [model setValue:resultValue forKeyPath:key];
            
        }];
    }
    
    return models;
}


+ (NSDictionary *)ColumnNameToValueRelationTypeDic {
    return @{
             @(ColumnNameToValueRelationTypeMore):@">",
             @(ColumnNameToValueRelationTypeLess):@"<",
             @(ColumnNameToValueRelationTypeEqual):@"=",
             @(ColumnNameToValueRelationTypeMoreEqual):@">=",
             @(ColumnNameToValueRelationTypeLessEqual):@"<="
             };
}


@end
