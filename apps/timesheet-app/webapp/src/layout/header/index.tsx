// Copyright (c) 2025 WSO2 LLC. (https://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import React from "react";
import { APP_NAME } from "@config/config";
import Toolbar from "@mui/material/Toolbar";
import Typography from "@mui/material/Typography";
import { useAppAuthContext } from "@context/AuthContext";
import { RootState, useAppSelector } from "@slices/store";
import { alpha, AppBar, Avatar, Box, Menu, MenuItem, Stack, Tooltip } from "@mui/material";

const Header = () => {
  const authContext = useAppAuthContext();
  const [anchorElUser, setAnchorElUser] = React.useState<null | HTMLElement>(null);
  const user = useAppSelector((state: RootState) => state.user);

  const handleOpenUserMenu = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorElUser(event.currentTarget);
  };

  const handleCloseUserMenu = () => {
    setAnchorElUser(null);
  };

  return (
    <AppBar
      position="fixed"
      sx={{
        zIndex: (theme) => theme.zIndex.drawer + 1,
        color: "black",

        background: (theme) => (theme.palette.mode === "light" ? theme.palette.common.white : "#0d0d0d"),
        boxShadow: 1,
      }}
    >
      <Toolbar
        variant="dense"
        sx={{
          paddingY: 0.3,
          "&.MuiToolbar-root": {
            pl: 0.3,
          },
        }}
      >
        <img
          alt="wso2"
          style={{
            height: "45px",
            maxWidth: "100px",
          }}
          onClick={() => (window.location.href = "/")}
          src={require("../../assets/images/wso2-logo.svg").default}
        ></img>
        <Typography
          variant="h5"
          sx={{
            ml: 1,
            flexGrow: 1,
            fontWeight: 600,
          }}
          color="primary"
        >
          {APP_NAME}
        </Typography>

        <Box sx={{ flexGrow: 0 }}>
          <>
            <Stack flexDirection={"row"} alignItems={"center"} gap={2}>
              <Box>
                <Typography variant="body1" sx={{ fontWeight: 600 }}>
                  {user.userInfo?.employeeInfo.firstName + " " + user.userInfo?.employeeInfo.lastName}
                </Typography>
                <Typography variant="body2">{user.userInfo?.jobRole}</Typography>
              </Box>
              <Tooltip title="Open settings">
                <Avatar
                  onClick={handleOpenUserMenu}
                  sx={{
                    width: 40,
                    height: 40,
                    boxShadow: (theme) =>
                      `0 0 0 2px ${theme.palette.background.paper}, 0 0 0 4px ${alpha(
                        theme.palette.primary.main,
                        0.3
                      )}`,
                  }}
                  src={user.userInfo?.employeeInfo.employeeThumbnail || ""}
                  alt={user.userInfo?.employeeInfo.firstName || "Avatar"}
                >
                  {user.userInfo?.employeeInfo.firstName?.charAt(0)}
                </Avatar>
              </Tooltip>
            </Stack>

            <Menu
              sx={{ mt: "45px" }}
              id="menu-appbar"
              anchorEl={anchorElUser}
              anchorOrigin={{
                vertical: "top",
                horizontal: "right",
              }}
              keepMounted
              transformOrigin={{
                vertical: "top",
                horizontal: "right",
              }}
              open={Boolean(anchorElUser)}
              onClose={handleCloseUserMenu}
            >
              <MenuItem
                key={"logout"}
                onClick={() => {
                  authContext.appSignOut();
                }}
              >
                <Typography textAlign="center">Logout</Typography>
              </MenuItem>
            </Menu>
          </>
        </Box>
      </Toolbar>
    </AppBar>
  );
};

export default Header;
