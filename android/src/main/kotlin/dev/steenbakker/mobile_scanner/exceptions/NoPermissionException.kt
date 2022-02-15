package dev.steenbakker.mobile_scanner.exceptions

internal class NoPermissionException : RuntimeException()

//internal class Exception(val reason: Reason) :
//        java.lang.Exception("Mobile Scanner failed because $reason") {
//
//    internal enum class Reason {
//        noHardware, noPermissions, noBackCamera
//    }
//}