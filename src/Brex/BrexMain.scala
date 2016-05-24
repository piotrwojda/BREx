package Brex

/**
  * Created by PWojda on 2016-05-23.
  */

import scala.io.Source


object BrexMain {

  def main(args: Array[String]): Unit = {

    val SqlKeyWords = List("INSERT", "UPDATE", "DELETE", "SELECT")
    val SqlSeparators = List(';')

    val fileName = "sp_MPA_ABB.sql"

    val bs = Source.fromFile(fileName)

    val sqlList = bs.getLines.toList

    val separatedSqlList = sqlList.map(_.trim).filterNot(_.startsWith("--")).map(_.replaceAll(";", "\\\n;")).map(_.replaceAll("^$", ";"))//.filterNot(_.equals(""))



    //val cleanSqlList = separatedSqlList.foldLeft(List[String]){ (z : String, i : String) => if(i.startsWith(";")) z  else z + i }
    val cleanSqlList = separatedSqlList.foldLeft("")((z,i) => z + " " + i).split(";").toList.map(_.trim).filterNot(_.equals("")).map(_.toUpperCase)

    //print(separatedSqlList.toString())

    cleanSqlList.foreach(println)
    //println(cleanSqlList)

    bs.close()

  }

  //def

//  def concStrings(concSqlText : List[String], sqlText : List[String]) : List[String] = {
//    sqlText match {
//      case x :: xs => if(!x.startsWith(";")) concStrings(concSqlText.last + x, xs) else concStrings(concSqlText, xs)
//      case _ => Nil
//    }
//  }

}
