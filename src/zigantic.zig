//! # zigantic
//!
//! Pydantic-like data validation and serialization for Zig.

const std = @import("std");

pub const types = @import("types.zig");
pub const validators = @import("validators.zig");
pub const errors = @import("errors.zig");
pub const json = @import("json.zig");
pub const version = @import("version.zig");
pub const report = @import("report.zig");

// ============================================================================
// LIBRARY CONFIGURATION
// ============================================================================

/// Configuration options for zigantic library.
pub const Config = struct {
    /// Whether to automatically check for library updates.
    /// Default is true. Set to false to disable automatic update checking.
    auto_update_check: bool = true,

    /// Whether to show update notifications in the log.
    /// Default is true. Set to false to suppress update messages.
    show_update_notifications: bool = true,
};

/// Global configuration - can be modified before first library use.
var global_config: Config = .{};

/// Thread handle for the background update check (if running).
var update_thread: ?std.Thread = null;

/// Flag indicating if the automatic update check has been triggered.
var update_check_triggered = false;
var update_check_mutex = std.Thread.Mutex{};

/// Set the library configuration. Call this BEFORE using any library functions
/// if you want to disable automatic update checking.
///
/// Example:
/// ```zig
/// const z = @import("zigantic");
///
/// pub fn main() !void {
///     // Disable automatic update checking (call before any other z.* functions)
///     z.setConfig(.{ .auto_update_check = false });
///
///     // Now use the library normally...
///     const name = try z.String(1, 50).init("Alice");
/// }
/// ```
pub fn setConfig(config: Config) void {
    update_check_mutex.lock();
    defer update_check_mutex.unlock();

    // Only allow config changes before first use
    if (!update_check_triggered) {
        global_config = config;
    }
}

/// Get the current library configuration.
pub fn getConfig() Config {
    return global_config;
}

/// Internal function to trigger automatic update check on first library use.
/// This is called automatically - users don't need to call this.
fn triggerAutoUpdateCheck(allocator: std.mem.Allocator) void {
    update_check_mutex.lock();
    defer update_check_mutex.unlock();

    if (update_check_triggered) return;
    update_check_triggered = true;

    if (global_config.auto_update_check and global_config.show_update_notifications) {
        update_thread = report.checkForUpdates(allocator);
    }
}

/// Disable automatic update checking. Convenience function.
/// Call this at the start of your program before using any library functions.
///
/// Example:
/// ```zig
/// const z = @import("zigantic");
///
/// pub fn main() !void {
///     z.disableUpdateCheck();
///
///     // Use library normally...
/// }
/// ```
pub fn disableUpdateCheck() void {
    setConfig(.{ .auto_update_check = false, .show_update_notifications = false });
}

// ============================================================================
// STRING TYPES
// ============================================================================

pub const String = types.String;
pub const NonEmptyString = types.NonEmptyString;
pub const Trimmed = types.Trimmed;
pub const Lowercase = types.Lowercase;
pub const Uppercase = types.Uppercase;
pub const Alphanumeric = types.Alphanumeric;
pub const AsciiString = types.AsciiString;
pub const Secret = types.Secret;
pub const StrongPassword = types.StrongPassword;

// ============================================================================
// NUMBER TYPES
// ============================================================================

pub const Int = types.Int;
pub const UInt = types.UInt;
pub const PositiveInt = types.PositiveInt;
pub const NonNegativeInt = types.NonNegativeInt;
pub const NegativeInt = types.NegativeInt;
pub const EvenInt = types.EvenInt;
pub const OddInt = types.OddInt;
pub const MultipleOf = types.MultipleOf;
pub const Float = types.Float;
pub const Percentage = types.Percentage;
pub const Probability = types.Probability;
pub const PositiveFloat = types.PositiveFloat;
pub const NegativeFloat = types.NegativeFloat;
pub const FiniteFloat = types.FiniteFloat;

// ============================================================================
// FORMAT TYPES
// ============================================================================

pub const Email = types.Email;
pub const Url = types.Url;
pub const HttpsUrl = types.HttpsUrl;
pub const Uuid = types.Uuid;
pub const Ipv4 = types.Ipv4;
pub const Ipv6 = types.Ipv6;
pub const Slug = types.Slug;
pub const Semver = types.Semver;
pub const PhoneNumber = types.PhoneNumber;
pub const CreditCard = types.CreditCard;
pub const Regex = types.Regex;

// ============================================================================
// COLLECTION TYPES
// ============================================================================

pub const List = types.List;
pub const NonEmptyList = types.NonEmptyList;
pub const FixedList = types.FixedList;

// ============================================================================
// SPECIAL TYPES
// ============================================================================

pub const Default = types.Default;
pub const Custom = types.Custom;
pub const Transform = types.Transform;
pub const Coerce = types.Coerce;
pub const Literal = types.Literal;
pub const Partial = types.Partial;
pub const OneOf = types.OneOf;
pub const Range = types.Range;
pub const Nullable = types.Nullable;
pub const Lazy = types.Lazy;

// ============================================================================
// CONVENIENCE FUNCTIONS
// ============================================================================

pub fn string(comptime min: usize, comptime max: usize) type {
    return String(min, max);
}
pub fn int(comptime T: type, comptime min: comptime_int, comptime max: comptime_int) type {
    return Int(T, min, max);
}
pub fn uint(comptime T: type, comptime min: comptime_int, comptime max: comptime_int) type {
    return UInt(T, min, max);
}
pub fn float(comptime T: type, comptime min: comptime_float, comptime max: comptime_float) type {
    return Float(T, min, max);
}
pub fn list(comptime T: type, comptime min: usize, comptime max: usize) type {
    return List(T, min, max);
}
pub fn default(comptime T: type, comptime val: T) type {
    return Default(T, val);
}
pub fn regex(comptime pattern: []const u8) type {
    return Regex(pattern);
}
pub fn custom(comptime T: type, comptime validator_fn: fn (T) bool) type {
    return Custom(T, validator_fn);
}
pub fn partial(comptime T: type) type {
    return Partial(T);
}
pub fn secret(comptime min: usize, comptime max: usize) type {
    return Secret(min, max);
}
pub fn literal(comptime T: type, comptime val: T) type {
    return Literal(T, val);
}
pub fn trimmed(comptime min: usize, comptime max: usize) type {
    return Trimmed(min, max);
}
pub fn oneOf(comptime T: type, comptime allowed: []const T) type {
    return OneOf(T, allowed);
}
pub fn range(comptime T: type, comptime start: comptime_int, comptime end: comptime_int, comptime step: comptime_int) type {
    return Range(T, start, end, step);
}
pub fn multipleOf(comptime T: type, comptime divisor: comptime_int) type {
    return MultipleOf(T, divisor);
}
pub fn nullable(comptime T: type) type {
    return Nullable(T);
}

// ============================================================================
// JSON FUNCTIONS
// ============================================================================

pub const ParseResult = json.ParseResult;
pub const ValidationError = errors.ValidationError;

/// Parse JSON with automatic validation.
/// Automatically checks for library updates on first use.
pub fn fromJson(comptime T: type, json_string: []const u8, allocator: std.mem.Allocator) !ParseResult(T) {
    triggerAutoUpdateCheck(allocator);
    return json.fromJson(T, json_string, allocator);
}

/// Serialize a value to JSON.
/// Automatically checks for library updates on first use.
pub fn toJson(value: anytype, allocator: std.mem.Allocator) ![]const u8 {
    triggerAutoUpdateCheck(allocator);
    return json.toJson(value, allocator);
}

/// Serialize a value to pretty-printed JSON.
/// Automatically checks for library updates on first use.
pub fn toJsonPretty(value: anytype, allocator: std.mem.Allocator) ![]const u8 {
    triggerAutoUpdateCheck(allocator);
    return json.toJsonPretty(value, allocator);
}

// ============================================================================
// VALIDATION HELPERS
// ============================================================================

/// Validate a value directly.
pub fn validate(comptime T: type, value: anytype) errors.ValidationError!T {
    return T.init(value);
}

/// Check if value is valid without throwing.
pub fn isValid(comptime T: type, value: anytype) bool {
    _ = T.init(value) catch return false;
    return true;
}

/// Get error message for a validation error.
pub fn errorMessage(err: errors.ValidationError) []const u8 {
    return errors.errorMessage(err);
}

/// Get error code for a validation error.
pub fn errorCode(err: errors.ValidationError) []const u8 {
    return errors.errorCode(err);
}

// ============================================================================
// VERSION AND REPORTING
// ============================================================================

/// URL for reporting issues on GitHub.
pub const ISSUES_URL = report.ISSUES_URL;

/// Get the current library version.
pub fn getVersion() []const u8 {
    return version.version;
}

/// Get the full version string with 'v' prefix.
pub fn getVersionString() []const u8 {
    return version.getVersionString();
}

/// Report an internal library error (for library bugs only, NOT validation errors).
/// Use this when you encounter an unexpected error that might be a bug in zigantic.
/// Do NOT use this for validation errors - those are expected behavior.
pub fn reportInternalError(message: []const u8) void {
    report.reportInternalError(message);
}

/// Report an internal library error with error code (for library bugs only).
pub fn reportInternalErrorWithCode(err: anyerror) void {
    report.reportInternalErrorWithCode(err);
}

// Legacy aliases
pub const reportError = reportInternalErrorWithCode;
pub const reportErrorMessage = reportInternalError;

/// Check for library updates in a background thread.
/// Returns a thread handle that can be joined on shutdown.
pub fn checkForUpdates(allocator: std.mem.Allocator) ?std.Thread {
    return report.checkForUpdates(allocator);
}

/// Synchronously check for updates and get update info.
pub fn checkForUpdatesSync(allocator: std.mem.Allocator) !report.UpdateInfo {
    return report.checkForUpdatesSync(allocator);
}

// ============================================================================
// TESTS
// ============================================================================

test "String basic" {
    const Name = String(1, 50);
    const name = try Name.init("Alice");
    try std.testing.expectEqualStrings("Alice", name.get());
}

test "Int range" {
    const Age = Int(i32, 18, 120);
    const age = try Age.init(25);
    try std.testing.expectEqual(@as(i32, 25), age.get());
    try std.testing.expectError(errors.ValidationError.TooSmall, Age.init(17));
}

test "Email domain" {
    const email = try Email.init("user@example.com");
    try std.testing.expectEqualStrings("example.com", email.domain());
}

test "Url https" {
    const url = try Url.init("https://example.com");
    try std.testing.expect(url.isHttps());
}

test "Default initDefault" {
    const Role = Default([]const u8, "user");
    const role = Role.initDefault();
    try std.testing.expectEqualStrings("user", role.get());
}

test "Custom validator" {
    const isEven = struct {
        fn f(n: i32) bool {
            return @mod(n, 2) == 0;
        }
    }.f;
    const Even = Custom(i32, isEven);
    const even = try Even.init(42);
    try std.testing.expectEqual(@as(i32, 42), even.get());
}

test "Partial fields" {
    const User = struct { name: []const u8, age: i32 };
    const PartialUser = Partial(User);
    var update: PartialUser = .{};
    update.name = "Alice";
    try std.testing.expect(update.age == null);
}

test "isValid helper" {
    try std.testing.expect(isValid(String(1, 50), "Alice"));
    try std.testing.expect(!isValid(String(1, 50), ""));
}

test "validate helper" {
    const name = try validate(String(1, 50), "Bob");
    try std.testing.expectEqualStrings("Bob", name.get());
}

test "PositiveInt" {
    const P = PositiveInt(i32);
    const p = try P.init(5);
    try std.testing.expect(p.isPositive());
}

test "Secret masking" {
    const Password = Secret(8, 100);
    const pwd = try Password.init("secretpass123");
    try std.testing.expectEqualStrings("********", pwd.masked());
}

test "OneOf" {
    const Status = OneOf(u8, &[_]u8{ 1, 2, 3 });
    _ = try Status.init(2);
    try std.testing.expectError(errors.ValidationError.NotInAllowedValues, Status.init(5));
}

test "Uuid" {
    const uuid = try Uuid.init("550e8400-e29b-41d4-a716-446655440000");
    try std.testing.expectEqual(@as(usize, 36), uuid.get().len);
}

test "Ipv4" {
    const ip = try Ipv4.init("192.168.1.1");
    try std.testing.expectEqualStrings("192.168.1.1", ip.get());
}

test "List" {
    const Tags = List([]const u8, 1, 5);
    const items = [_][]const u8{ "a", "b" };
    const tags = try Tags.init(&items);
    try std.testing.expectEqual(@as(usize, 2), tags.len());
}

test "Trimmed" {
    const Input = Trimmed(1, 50);
    const input = try Input.init("  hello  ");
    try std.testing.expectEqualStrings("hello", input.get());
}

test "EvenInt" {
    const E = EvenInt(i32, 0, 100);
    _ = try E.init(42);
    try std.testing.expectError(errors.ValidationError.MustBeEven, E.init(43));
}

test "MultipleOf" {
    const M = MultipleOf(i32, 5);
    _ = try M.init(25);
    try std.testing.expectError(errors.ValidationError.NotMultiple, M.init(23));
}

test "HttpsUrl" {
    _ = try HttpsUrl.init("https://example.com");
    try std.testing.expectError(errors.ValidationError.MustBeHttps, HttpsUrl.init("http://example.com"));
}

test "Range" {
    const R = Range(i32, 0, 100, 10);
    _ = try R.init(50);
    try std.testing.expectError(errors.ValidationError.NotInStep, R.init(55));
}

test "StrongPassword" {
    const Pwd = StrongPassword(8, 100);
    _ = try Pwd.init("P@ssw0rd!");
    try std.testing.expectError(errors.ValidationError.WeakPassword, Pwd.init("password"));
}

test "Nullable" {
    const N = Nullable(i32);
    const some = N.init(42);
    const none = N.initNull();
    try std.testing.expect(!some.isNull());
    try std.testing.expect(none.isNull());
}

test "errorMessage" {
    try std.testing.expectEqualStrings("value is too short", errorMessage(errors.ValidationError.TooShort));
}

test "errorCode" {
    try std.testing.expectEqualStrings("E001", errorCode(errors.ValidationError.TooShort));
}

test {
    std.testing.refAllDecls(@This());
}
