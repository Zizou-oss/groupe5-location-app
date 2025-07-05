const checkRole = (allowedRoles) => {
  return (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ message: "Rôle non autorisé" });
    }
    next();
  };
};

module.exports = checkRole;
